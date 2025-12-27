import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/preferences/domain/models/user_preferences.dart';

/// Repository pour gérer les préférences utilisateur
class UserPreferencesRepository {
  final SupabaseService _supabaseService;

  UserPreferencesRepository(this._supabaseService);

  /// Récupère les préférences d'un utilisateur
  Future<UserPreferences?> getUserPreferences(int userId) async {
    try {
      final response = await _supabaseService.client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des préférences: $e');
    }
  }

  /// Crée ou met à jour les préférences d'un utilisateur
  Future<UserPreferences> saveUserPreferences({
    required int userId,
    required List<String> divinitesPreferees,
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

        return UserPreferences.fromJson(response);
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

        return UserPreferences.fromJson(response);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des préférences: $e');
    }
  }

  /// Met à jour uniquement les divinités préférées
  Future<UserPreferences> updateDivinitesPreferees({
    required int userId,
    required List<String> divinitesPreferees,
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

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des divinités: $e');
    }
  }

  /// Met à jour la préférence pour assister aux rituels
  Future<UserPreferences> updateAssisterRituel({
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

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception(
        'Erreur lors de la mise à jour de la préférence rituel: $e',
      );
    }
  }

  /// Met à jour la devise préférée
  Future<UserPreferences> updatePreferredCurrency({
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

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la devise: $e');
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
      throw Exception('Erreur lors de la suppression des préférences: $e');
    }
  }

  /// Vérifie si l'utilisateur a complété le questionnaire
  Future<bool> hasCompletedQuestionnaire(int userId) async {
    try {
      final preferences = await getUserPreferences(userId);
      return preferences?.isCompleted ?? false;
    } catch (e) {
      return false;
    }
  }
}
