import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/data/repositories/auth_repository.dart';
import 'package:vodou/features/auth/domain/models/user.dart' as app_user;

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
    print(
      '👂 AuthProvider: Écoute des changements d\'authentification activée',
    );
    _authSubscription = SupabaseService.instance.authStateChanges.listen(
      (AuthState authState) {
        final event = authState.event;
        print('🔔 AuthProvider: Événement auth reçu: $event');

        // Recharger l'utilisateur lors des changements d'auth
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          print(
            '🔄 AuthProvider: Rechargement de l\'utilisateur suite à: $event',
          );
          _loadCurrentUser();
        } else if (event == AuthChangeEvent.signedOut) {
          print('👋 AuthProvider: Déconnexion détectée');
          state = const AsyncValue.data(null);
        }
      },
      onError: (error) {
        print('❌ AuthProvider: Erreur dans le stream auth: $error');
      },
    );
  }

  Future<void> _loadCurrentUser() async {
    print('🔄 AuthProvider: Chargement de l\'utilisateur actuel...');
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        print(
          '✅ AuthProvider: Utilisateur chargé: ${user.fullName} (${user.email})',
        );
      } else {
        print('⚠️ AuthProvider: Aucun utilisateur connecté');
      }
      state = AsyncValue.data(user);
    } catch (e, stack) {
      print('❌ AuthProvider: Erreur lors du chargement: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Inscription avec email
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
      final user = await _authRepository.signUpWithEmail(
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
      state = AsyncValue.data(user);
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
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
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
  Future<void> signInWithGoogle() async {
    try {
      print('🔵 AuthProvider: Début connexion Google...');
      state = const AsyncValue.loading();
      final user = await _authRepository.signInWithGoogle();
      state = AsyncValue.data(user);
      print('✅ AuthProvider: Connexion Google réussie');
    } catch (e, stack) {
      print('❌ AuthProvider: Erreur Google - $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Connexion avec Facebook
  Future<void> signInWithFacebook() async {
    try {
      print('🔵 AuthProvider: Début connexion Facebook...');
      state = const AsyncValue.loading();
      final user = await _authRepository.signInWithFacebook();
      state = AsyncValue.data(user);
      print('✅ AuthProvider: Connexion Facebook réussie');
    } catch (e, stack) {
      print('❌ AuthProvider: Erreur Facebook - $e');
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
