import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/features/messaging/domain/models/chat_message.dart';
import 'package:vodou/features/messaging/domain/models/conversation_model.dart';

class MessagingRepository {
  final SupabaseClient _supabase;

  MessagingRepository(this._supabase);

  /// Récupérer toutes les conversations de l'utilisateur
  Future<List<ConversationModel>> getConversations(int userId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            logement:logements(id, titre, prix_par_nuit),
            visiteur:users!visiteur_id(id, nom, prenom, photo),
            hote:users!hote_id(id, nom, prenom, photo)
          ''')
          .or('visiteur_id.eq.$userId,hote_id.eq.$userId')
          .order('updated_at', ascending: false);

      final conversations = (response as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();

      // Charger le dernier message et le nombre de messages non lus pour chaque conversation
      for (var conversation in conversations) {
        final dernierMessage = await _getDernierMessage(conversation.id);
        final messagesNonLus = await _getMessagesNonLusCount(
          conversation.id,
          userId,
        );

        conversations[conversations.indexOf(conversation)] = conversation
            .copyWith(
              dernierMessage: dernierMessage,
              messagesNonLus: messagesNonLus,
            );
      }

      return conversations;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conversations: $e');
    }
  }

  /// Récupérer une conversation spécifique
  Future<ConversationModel?> getConversation(int conversationId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            logement:logements(id, titre, prix_par_nuit),
            visiteur:users!visiteur_id(id, nom, prenom, photo),
            hote:users!hote_id(id, nom, prenom, photo)
          ''')
          .eq('id', conversationId)
          .single();

      return ConversationModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Récupérer ou créer une conversation entre un visiteur et un hôte pour un logement
  Future<ConversationModel> getOrCreateConversation({
    required int visiteurId,
    required int hoteId,
    int? logementId,
  }) async {
    try {
      // Vérifier si une conversation existe déjà
      var query = _supabase
          .from('conversations')
          .select('''
            *,
            logement:logements(id, titre, prix_par_nuit),
            visiteur:users!visiteur_id(id, nom, prenom, photo),
            hote:users!hote_id(id, nom, prenom, photo)
          ''')
          .eq('visiteur_id', visiteurId)
          .eq('hote_id', hoteId);

      if (logementId != null) {
        query = query.eq('logement_id', logementId);
      }

      final existing = await query.maybeSingle();

      if (existing != null) {
        return ConversationModel.fromJson(existing);
      }

      // Créer une nouvelle conversation
      final newConversation = await _supabase
          .from('conversations')
          .insert({
            'visiteur_id': visiteurId,
            'hote_id': hoteId,
            if (logementId != null) 'logement_id': logementId,
          })
          .select('''
            *,
            logement:logements(id, titre, prix_par_nuit),
            visiteur:users!visiteur_id(id, nom, prenom, photo),
            hote:users!hote_id(id, nom, prenom, photo)
          ''')
          .single();

      print('📝 Conversation créée: $newConversation');
      return ConversationModel.fromJson(newConversation);
    } catch (e, stackTrace) {
      print('❌ Erreur création conversation: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Erreur lors de la création de la conversation: $e');
    }
  }

  /// Récupérer les messages d'une conversation
  Future<List<ChatMessage>> getMessages(int conversationId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender:users!sender_id(id, nom, prenom, photo)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des messages: $e');
    }
  }

  /// Envoyer un message
  Future<ChatMessage> sendMessage({
    required int conversationId,
    required int senderId,
    String? message,
    String? attachment,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            if (message != null) 'message': message,
            if (attachment != null) 'attachment': attachment,
            'is_read': false,
          })
          .select('''
            *,
            sender:users!sender_id(id, nom, prenom, photo)
          ''')
          .single();

      // Mettre à jour la date de la conversation
      await _supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      return ChatMessage.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  /// Marquer un message comme lu
  Future<void> markAsRead(int messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Erreur lors du marquage du message: $e');
    }
  }

  /// Marquer tous les messages d'une conversation comme lus
  Future<void> markConversationAsRead(int conversationId, int userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Erreur lors du marquage de la conversation: $e');
    }
  }

  /// Récupérer le dernier message d'une conversation
  Future<ChatMessage?> _getDernierMessage(int conversationId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender:users!sender_id(id, nom, prenom, photo)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return ChatMessage.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Compter les messages non lus d'une conversation
  Future<int> _getMessagesNonLusCount(int conversationId, int userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Compter le total de messages non lus de l'utilisateur
  Future<int> getTotalUnreadCount(int userId) async {
    try {
      // Récupérer toutes les conversations de l'utilisateur
      final conversations = await _supabase
          .from('conversations')
          .select('id')
          .or('visiteur_id.eq.$userId,hote_id.eq.$userId');

      final conversationIds = (conversations as List)
          .map((c) => c['id'] as int)
          .toList();

      if (conversationIds.isEmpty) return 0;

      // Compter les messages non lus dans ces conversations
      final response = await _supabase
          .from('messages')
          .select('id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Rechercher dans les conversations
  Future<List<ConversationModel>> searchConversations(
    int userId,
    String query,
  ) async {
    try {
      final allConversations = await getConversations(userId);

      // Filtrer localement par nom de participant ou titre de logement
      return allConversations.where((conv) {
        final nomParticipant = conv.getNomParticipant(userId).toLowerCase();
        final titreLogement = conv.getTitreLogement()?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return nomParticipant.contains(searchQuery) ||
            titreLogement.contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
}
