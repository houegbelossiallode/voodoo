import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/core/services/file_upload_service.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/messaging/data/repositories/messaging_repository.dart';
import 'package:vodou/features/messaging/domain/models/chat_message.dart';
import 'package:vodou/features/messaging/domain/models/conversation_filter.dart';
import 'package:vodou/features/messaging/domain/models/conversation_model.dart';

/// Provider du repository
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(Supabase.instance.client);
});

/// Provider du service d'upload de fichiers
final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  final supabaseService = SupabaseService.instance;
  return FileUploadService(supabaseService);
});

/// Provider des conversations
final conversationsProvider = FutureProvider<List<ConversationModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getConversations(user.id);
});

/// Provider du filtre actif
final conversationFilterProvider = StateProvider<ConversationFilter>((ref) {
  return ConversationFilter.all;
});

/// Provider de la recherche
final conversationSearchProvider = StateProvider<String>((ref) {
  return '';
});

/// Provider des conversations filtrées
final filteredConversationsProvider =
    Provider<AsyncValue<List<ConversationModel>>>((ref) {
      final conversationsAsync = ref.watch(conversationsProvider);
      final filter = ref.watch(conversationFilterProvider);
      final searchQuery = ref.watch(conversationSearchProvider);
      final user = ref.watch(currentUserProvider).value;

      return conversationsAsync.whenData((conversations) {
        var filtered = conversations;

        // Appliquer le filtre
        if (filter != ConversationFilter.all && user != null) {
          final userId = user.id;
          filtered = filtered.where((conv) {
            switch (filter) {
              case ConversationFilter.hosts:
                return conv.visiteurId ==
                    userId; // Je suis visiteur, donc messages avec hôtes
              case ConversationFilter.visitors:
                return conv.hoteId ==
                    userId; // Je suis hôte, donc messages avec visiteurs
              case ConversationFilter.support:
              case ConversationFilter.translators:
              case ConversationFilter.photographers:
                // TODO: Implémenter ces filtres selon la logique métier
                return false;
              default:
                return true;
            }
          }).toList();
        }

        // Appliquer la recherche
        if (searchQuery.isNotEmpty && user != null) {
          final userId = user.id;
          final query = searchQuery.toLowerCase();
          filtered = filtered.where((conv) {
            final nomParticipant = conv.getNomParticipant(userId).toLowerCase();
            final titreLogement = conv.getTitreLogement()?.toLowerCase() ?? '';
            return nomParticipant.contains(query) ||
                titreLogement.contains(query);
          }).toList();
        }

        return filtered;
      });
    });

/// Provider du nombre total de messages non lus
final unreadMessagesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return 0;

  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getTotalUnreadCount(user.id);
});

/// Provider des messages d'une conversation
final conversationMessagesProvider =
    FutureProvider.family<List<ChatMessage>, int>((ref, conversationId) async {
      final repository = ref.watch(messagingRepositoryProvider);
      return repository.getMessages(conversationId);
    });

/// Provider d'une conversation spécifique
final conversationProvider = FutureProvider.family<ConversationModel?, int>((
  ref,
  conversationId,
) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getConversation(conversationId);
});

/// Notifier pour envoyer des messages
class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  final MessagingRepository _repository;

  SendMessageNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> sendMessage({
    required int conversationId,
    required int senderId,
    String? message,
    String? attachment,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        message: message,
        attachment: attachment,
      );
    });
  }
}

final sendMessageProvider =
    StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(messagingRepositoryProvider);
      return SendMessageNotifier(repository);
    });

/// Notifier pour créer/récupérer une conversation
class ConversationCreatorNotifier
    extends StateNotifier<AsyncValue<ConversationModel?>> {
  final MessagingRepository _repository;

  ConversationCreatorNotifier(this._repository)
    : super(const AsyncValue.data(null));

  Future<ConversationModel?> getOrCreateConversation({
    required int visiteurId,
    required int hoteId,
    int? logementId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getOrCreateConversation(
        visiteurId: visiteurId,
        hoteId: hoteId,
        logementId: logementId,
      );
    });
    return state.value;
  }
}

final conversationCreatorProvider =
    StateNotifierProvider<
      ConversationCreatorNotifier,
      AsyncValue<ConversationModel?>
    >((ref) {
      final repository = ref.watch(messagingRepositoryProvider);
      return ConversationCreatorNotifier(repository);
    });
