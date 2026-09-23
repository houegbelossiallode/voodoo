import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/data/repositories/auth_repository.dart';
import 'package:vodou/features/auth/domain/models/user.dart' as app_user;
import 'package:vodou/core/utils/app_logger.dart';

/// Provider pour le repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider pour l'utilisateur actuel
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<app_user.User?>>((
      ref,
    ) {
      return CurrentUserNotifier(ref.read(authRepositoryProvider));
    });

/// Notifier pour gérer l'état de l'utilisateur actuel
class CurrentUserNotifier extends StateNotifier<AsyncValue<app_user.User?>> {
  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _authSubscription;

  CurrentUserNotifier(this._authRepository)
    : super(const AsyncValue.loading()) {
    _loadCurrentUser();
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Écoute les changements d'authentification Supabase
  void _listenToAuthChanges() {
    AppLogger.d(
      '👂 AuthProvider: Écoute des changements d\'authentification activée',
    );
    _authSubscription = SupabaseService.instance.authStateChanges.listen(
      (AuthState authState) async {
        final event = authState.event;
        AppLogger.d('🔔 AuthProvider: Événement auth reçu: $event');

        // Recharger l'utilisateur lors de la connexion et des événements majeurs
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated ||
            event == AuthChangeEvent.initialSession) {
          AppLogger.d(
            '🔄 AuthProvider: Rechargement automatique du profil suite à: $event',
          );
          await _loadCurrentUser();

          // Si c'est une connexion via deep link (confirmation email), rediriger vers home
          if (event == AuthChangeEvent.signedIn && state.value != null) {
            AppLogger.d(
              '✅ Connexion via deep link détectée - Redirection vers home',
            );
            // La redirection sera gérée par le router automatiquement
          }
        } else if (event == AuthChangeEvent.passwordRecovery) {
          AppLogger.d(
            '🔑 AuthProvider: Événement de récupération de mot de passe reçu',
          );
          // En cas de récupération de mot de passe, tenter le chargement mais ne pas bloquer l'état si non trouvé
          try {
            final user = await _authRepository.getCurrentUser();
            state = AsyncValue.data(user);
          } catch (_) {
            state = const AsyncValue.data(null);
          }
        } else if (event == AuthChangeEvent.signedOut) {
          AppLogger.d('👋 AuthProvider: Déconnexion détectée');
          state = const AsyncValue.data(null);
        }
      },
      onError: (error) {
        AppLogger.e('❌ AuthProvider: Erreur dans le stream auth: $error');
      },
    );
  }

  Future<void> _loadCurrentUser() async {
    AppLogger.d('🔄 AuthProvider: Chargement de l\'utilisateur actuel...');
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.getCurrentUser().timeout(
        const Duration(seconds: 6),
      );
      if (user != null) {
        AppLogger.d('AuthProvider: utilisateur chargé', {'id': user.id});
      } else {
        AppLogger.w('⚠️ AuthProvider: Aucun utilisateur connecté');
      }
      state = AsyncValue.data(user);
    } catch (e) {
      AppLogger.w('⚠️ AuthProvider: Chargement ignoré ou délai dépassé: $e');
      state = const AsyncValue.data(null);
    }
  }

  /// Inscription avec email
  /// Note: Le profil sera créé après confirmation email lors de la première connexion
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String profession,
    required int roleId,
    List<String>? langue,
    List<String>? passions,
    String? bio,
  }) async {
    try {
      await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        profession: profession,
        roleId: roleId,
        langue: langue,
        passions: passions,
        bio: bio,
      );
      // L'état reste null car l'utilisateur doit confirmer son email
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Connexion avec email
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
    try {
      await _authRepository.signOut();
    } catch (e, stack) {
      AppLogger.e('Erreur déconnexion AuthProvider', e, stack);
    }
  }

  /// Mise à jour du profil
  Future<void> updateProfile({
    String? nom,
    String? prenom,
    String? bio,
    String? telephone,
    String? photo,
    List<String>? langue,
    String? profession,
    List<String>? passions,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      final updatedUser = await _authRepository.updateUserProfile(
        userId: currentUser.id, // id est maintenant int
        nom: nom,
        prenom: prenom,
        bio: bio,
        telephone: telephone,
        photo: photo,
        langue: langue,
        profession: profession,
        passions: passions,
      );
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Changement de mot de passe
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authRepository.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  /// Rafraîchir l'utilisateur
  Future<void> refresh() async {
    await _loadCurrentUser();
  }

  /// Connexion avec Google
  Future<GoogleAuthResult?> signInWithGoogle() async {
    try {
      AppLogger.d('🔵 AuthProvider: Début connexion Google...');
      state = const AsyncValue.loading();
      final result = await _authRepository.signInWithGoogle();

      if (result != null && !result.isNewUser && result.user != null) {
        state = AsyncValue.data(result.user);
        AppLogger.d(
          '✅ AuthProvider: Connexion Google utilisateur existant réussie',
        );
      } else {
        // Nouveau compte ou annulation : attente de sélection du rôle
        state = const AsyncValue.data(null);
      }
      return result;
    } catch (e, stack) {
      AppLogger.e('❌ AuthProvider: Erreur Google - $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Finaliser la création du profil OAuth après la sélection du rôle
  Future<void> completeOAuthProfile({
    required String supabaseId,
    required String email,
    required String nom,
    required String prenom,
    required int roleId,
    String? photo,
  }) async {
    try {
      AppLogger.d(
        '📝 AuthProvider: Création du profil Google avec le rôle $roleId...',
      );
      state = const AsyncValue.loading();
      final user = await _authRepository.createOAuthUserProfile(
        supabaseId: supabaseId,
        email: email,
        nom: nom,
        prenom: prenom,
        roleId: roleId,
        photo: photo,
      );
      state = AsyncValue.data(user);
      AppLogger.d('✅ AuthProvider: Profil Google créé avec succès !');
    } catch (e, stack) {
      AppLogger.e('❌ AuthProvider: Erreur finalisation profil OAuth - $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Connexion avec Facebook
  Future<void> signInWithFacebook() async {
    try {
      AppLogger.d('🔵 AuthProvider: Début connexion Facebook...');
      state = const AsyncValue.loading();
      final user = await _authRepository.signInWithFacebook();
      state = AsyncValue.data(user);
      AppLogger.d('✅ AuthProvider: Connexion Facebook réussie');
    } catch (e, stack) {
      AppLogger.e('❌ AuthProvider: Erreur Facebook - $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider pour vérifier si l'utilisateur est authentifié
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
