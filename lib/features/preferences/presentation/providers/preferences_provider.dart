import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/preferences/data/repositories/user_preferences_repository.dart';
import 'package:vodou/features/auth/domain/models/user.dart' as app_user;
import 'package:vodou/core/utils/app_logger.dart';

/// Provider pour le repository des préférences
final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository>((
  ref,
) {
  final supabaseService = SupabaseService.instance;
  return UserPreferencesRepository(supabaseService);
});

/// Provider pour récupérer les préférences de l'utilisateur actuel
final currentUserPreferencesProvider =
    FutureProvider<app_user.UserPreferences?>((ref) async {
      final userAsync = ref.watch(currentUserProvider);
      final user = userAsync.value;

      if (user == null) return null;

      final repository = ref.watch(userPreferencesRepositoryProvider);
      return repository.getUserPreferences(user.id);
    });

/// Provider pour vérifier si l'utilisateur a complété le questionnaire
final hasCompletedQuestionnaireProvider = FutureProvider<bool>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;

  if (user == null) return false;

  try {
    final repository = ref.watch(userPreferencesRepositoryProvider);
    return await repository.hasCompletedQuestionnaire(user.id);
  } catch (e) {
    // Si erreur (table n'existe pas), considérer comme non complété
    AppLogger.w('⚠️ Erreur hasCompletedQuestionnaire: $e');
    return false;
  }
});

/// StateNotifier pour gérer les préférences utilisateur
class UserPreferencesNotifier
    extends StateNotifier<AsyncValue<app_user.UserPreferences?>> {
  final UserPreferencesRepository _repository;
  final int? userId;

  UserPreferencesNotifier(this._repository, this.userId)
    : super(const AsyncValue.loading()) {
    if (userId != null) {
      _loadPreferences();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Charge les préférences de l'utilisateur
  Future<void> _loadPreferences() async {
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final preferences = await _repository.getUserPreferences(userId!);
      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sauvegarde les préférences complètes
  Future<void> savePreferences({
    required List<int> divinitesPreferees,
    required bool assisterRituel,
    String? preferredCurrency,
  }) async {
    if (userId == null) return;

    state = const AsyncValue.loading();

    try {
      final preferences = await _repository.saveUserPreferences(
        userId: userId!,
        divinitesPreferees: divinitesPreferees,
        assisterRituel: assisterRituel,
        preferredCurrency: preferredCurrency,
      );

      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Met à jour uniquement les divinités préférées
  Future<void> updateDivinitesPreferees(List<int> divinitesPreferees) async {
    if (userId == null) return;

    try {
      final preferences = await _repository.updateDivinitesPreferees(
        userId: userId!,
        divinitesPreferees: divinitesPreferees,
      );

      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Met à jour la préférence pour assister aux rituels
  Future<void> updateAssisterRituel(bool assisterRituel) async {
    if (userId == null) return;

    try {
      final preferences = await _repository.updateAssisterRituel(
        userId: userId!,
        assisterRituel: assisterRituel,
      );

      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Met à jour la devise préférée
  Future<void> updatePreferredCurrency(String currency) async {
    if (userId == null) return;

    try {
      final preferences = await _repository.updatePreferredCurrency(
        userId: userId!,
        currency: currency,
      );

      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Rafraîchit les préférences
  Future<void> refresh() async {
    await _loadPreferences();
  }
}

/// Provider pour le notifier des préférences
final userPreferencesNotifierProvider =
    StateNotifierProvider<
      UserPreferencesNotifier,
      AsyncValue<app_user.UserPreferences?>
    >((ref) {
      final repository = ref.read(userPreferencesRepositoryProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;

      return UserPreferencesNotifier(repository, user?.id);
    });
