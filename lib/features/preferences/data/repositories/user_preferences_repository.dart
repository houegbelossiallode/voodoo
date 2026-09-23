import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/domain/models/user.dart' as app_user;
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Repository pour gérer les préférences utilisateur
class UserPreferencesRepository {
  final SupabaseService _supabaseService;

  UserPreferencesRepository(this._supabaseService);

  /// Récupère les préférences d'un utilisateur
  Future<app_user.UserPreferences?> getUserPreferences(int userId) async {
    try {
      final response = await _supabaseService.client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return app_user.UserPreferences.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des préférences',
      );
    }
  }

  /// Crée ou met à jour les préférences d'un utilisateur
  Future<app_user.UserPreferences> saveUserPreferences({
    required int userId,
    required List<int> divinitesPreferees,
    required bool assisterRituel,
    String? preferredCurrency,
  }) async {
    try {
      // Vérifier si les préférences existent déjà
      final existing = await getUserPreferences(userId);

      if (existing != null) {
        // Mise à jour
        final response = await _supabaseService.client
            .from('user_preferences')
            .update({
              'divinites_preferees': divinitesPreferees,
              'assister_rituel': assisterRituel,
              'preferred_currency': preferredCurrency ?? 'XOF',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .select()
            .single();

        return app_user.UserPreferences.fromJson(response);
      } else {
        // Création
        final response = await _supabaseService.client
            .from('user_preferences')
            .insert({
              'user_id': userId,
              'divinites_preferees': divinitesPreferees,
              'assister_rituel': assisterRituel,
              'preferred_currency': preferredCurrency ?? 'XOF',
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        return app_user.UserPreferences.fromJson(response);
      }
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la sauvegarde des préférences',
      );
    }
  }

  /// Met à jour uniquement les divinités préférées
  Future<app_user.UserPreferences> updateDivinitesPreferees({
    required int userId,
    required List<int> divinitesPreferees,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('user_preferences')
          .update({
            'divinites_preferees': divinitesPreferees,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .select()
          .single();

      return app_user.UserPreferences.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la mise à jour des divinités',
      );
    }
  }

  /// Met à jour la préférence pour assister aux rituels
  Future<app_user.UserPreferences> updateAssisterRituel({
    required int userId,
    required bool assisterRituel,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('user_preferences')
          .update({
            'assister_rituel': assisterRituel,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .select()
          .single();

      return app_user.UserPreferences.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la mise à jour de la préférence rituel',
      );
    }
  }

  /// Met à jour la devise préférée
  Future<app_user.UserPreferences> updatePreferredCurrency({
    required int userId,
    required String currency,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('user_preferences')
          .update({
            'preferred_currency': currency,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .select()
          .single();

      return app_user.UserPreferences.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la mise à jour de la devise',
      );
    }
  }

  /// Supprime les préférences d'un utilisateur
  Future<void> deleteUserPreferences(int userId) async {
    try {
      await _supabaseService.client
          .from('user_preferences')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la suppression des préférences',
      );
    }
  }

  /// Vérifie si l'utilisateur a complété le questionnaire
  Future<bool> hasCompletedQuestionnaire(int userId) async {
    try {
      AppLogger.d('🔍 hasCompletedQuestionnaire - userId: $userId');
      final preferences = await getUserPreferences(userId);
      AppLogger.d('   📦 preferences: $preferences');

      if (preferences == null) {
        AppLogger.e('   ❌ Aucune préférence trouvée → hasCompleted = FALSE');
        return false;
      }

      AppLogger.d(
        '   📋 divinitesPreferees: ${preferences.divinitesPreferees}',
      );
      AppLogger.d('   📊 hasPreferences: ${preferences.hasPreferences}');

      final result = preferences.hasPreferences;
      AppLogger.d('   ✅ Résultat final → hasCompleted = $result');

      return result;
    } catch (e) {
      AppLogger.w('   ⚠️ Erreur dans hasCompletedQuestionnaire: $e');
      return false;
    }
  }
}
