import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/domain/models/user.dart' as app_user;

/// Repository pour gérer l'authentification avec Supabase
class AuthRepository {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Inscription avec email et mot de passe
  Future<app_user.User?> signUpWithEmail({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String profession,
    List<String>? langue,
    List<String>? passions,
    String? bio,
  }) async {
    try {
      // 1. Récupérer l'ID du rôle "Visiteur"
      final roleResponse = await _supabase
          .from(SupabaseConfig.rolesTable)
          .select('id')
          .eq('libelle', 'Visiteur')
          .single();

      final visiteurRoleId = roleResponse['id'] as int;

      // 2. Créer le compte Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // 3. Créer le profil dans la table users
      // L'id sera auto-généré par PostgreSQL
      final userProfile = await _supabase
          .from(SupabaseConfig.usersTable)
          .insert({
            'supabase_id': authResponse.user!.id, // UUID de Supabase Auth
            'nom': nom,
            'prenom': prenom,
            'email': email,
            'telephone': telephone,
            'profession': profession,
            'langue': langue ?? ['fr'],
            'passions': passions ?? [],
            'bio': bio,
            'role_id': visiteurRoleId, // Rôle "Visiteur" récupéré dynamiquement
            'actif': 'OUI',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return app_user.User.fromJson(userProfile);
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Connexion avec email et mot de passe
  Future<app_user.User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('📡 AuthRepository: Appel Supabase signInWithPassword...');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('📡 AuthRepository: Réponse Supabase reçue');
      print('📡 User ID: ${response.user?.id}');

      if (response.user != null) {
        print('📡 AuthRepository: Récupération du profil utilisateur...');
        final user = await _getUserProfile(response.user!.id);
        print('📡 AuthRepository: Profil récupéré: ${user?.fullName}');
        return user;
      }
      print('⚠️ AuthRepository: Aucun utilisateur dans la réponse');
      return null;
    } catch (e) {
      print('❌ AuthRepository: Erreur - $e');
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  /// Récupère le profil utilisateur depuis la base de données par supabase_id
  Future<app_user.User?> _getUserProfile(String supabaseId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('''
            *,
            role:${SupabaseConfig.rolesTable}!role_id(libelle)
          ''')
          .eq('supabase_id', supabaseId) // Recherche par supabase_id
          .eq('actif', 'OUI')
          .single();

      return app_user.User.fromJson(response);
    } catch (e) {
      // Si le profil n'existe pas encore
      return null;
    }
  }

  /// Récupère l'utilisateur actuellement connecté
  Future<app_user.User?> getCurrentUser() async {
    print('🔍 AuthRepository.getCurrentUser: Vérification session Supabase...');
    final user = _supabase.auth.currentUser;

    if (user == null) {
      print('⚠️ AuthRepository.getCurrentUser: Aucune session Supabase active');
      return null;
    }

    print(
      '✅ AuthRepository.getCurrentUser: Session trouvée pour user ID: ${user.id}',
    );
    final profile = await _getUserProfile(user.id);

    if (profile != null) {
      print(
        '✅ AuthRepository.getCurrentUser: Profil récupéré: ${profile.fullName}',
      );
    } else {
      print(
        '⚠️ AuthRepository.getCurrentUser: Profil non trouvé dans la table users',
      );
    }

    return profile;
  }

  /// Met à jour le profil utilisateur par id (auto-incrémenté)
  Future<app_user.User?> updateUserProfile({
    required int userId, // ID auto-incrémenté PostgreSQL
    String? nom,
    String? prenom,
    String? bio,
    String? telephone,
    String? photo,
    List<String>? langue,
    String? profession,
    List<String>? passions,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nom != null) updates['nom'] = nom;
      if (prenom != null) updates['prenom'] = prenom;
      if (bio != null) updates['bio'] = bio;
      if (telephone != null) updates['telephone'] = telephone;
      if (photo != null) updates['photo'] = photo;
      if (langue != null) updates['langue'] = langue;
      if (profession != null) updates['profession'] = profession;
      if (passions != null) updates['passions'] = passions;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .update(updates)
          .eq('id', userId) // Utilise l'id auto-incrémenté
          .select()
          .single();

      return app_user.User.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Change le mot de passe de l'utilisateur
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception('Erreur lors du changement de mot de passe: $e');
    }
  }

  /// Vérifie si l'utilisateur est connecté
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Récupère le Supabase ID de l'utilisateur connecté
  String? getCurrentSupabaseId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Stream de l'état d'authentification
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  Future<app_user.User?> signInWithGoogle() async {
    try {
      print('🔵 AuthRepository: Début authentification Google...');
      print('🔍 DEBUG: Web Client ID = ${SupabaseConfig.googleClientId}');
      print(
        '🔍 DEBUG: Android Client ID = ${SupabaseConfig.googleAndroidClientId}',
      );

      // 1. Initialiser Google Sign In
      // TEST: Utilise le Android Client ID pour vérifier si le SHA-1 fonctionne
      print('🔍 DEBUG: Initialisation GoogleSignIn...');
      print('🔍 DEBUG: TEST - Utilisation du Android Client ID');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.googleAndroidClientId,
        scopes: ['email', 'profile', 'openid'],
      );
      print('✅ DEBUG: GoogleSignIn initialisé');

      // 2. Connexion Google
      print('🔍 DEBUG: Appel googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ AuthRepository: Connexion Google annulée par l\'utilisateur');
        return null;
      }

      print(
        '✅ AuthRepository: Utilisateur Google sélectionné: ${googleUser.email}',
      );
      print('🔍 DEBUG: displayName = ${googleUser.displayName}');
      print('🔍 DEBUG: photoUrl = ${googleUser.photoUrl}');

      // 3. Récupérer les tokens
      print('🔍 DEBUG: Récupération des tokens Google...');
      try {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final String? accessToken = googleAuth.accessToken;
        final String? idToken = googleAuth.idToken;

        print('🔍 DEBUG: accessToken présent: ${accessToken != null}');
        print('🔍 DEBUG: idToken présent: ${idToken != null}');

        if (accessToken != null) {
          print(
            '🔍 DEBUG: accessToken (premiers 20 chars): ${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...',
          );
        }
        if (idToken != null) {
          print(
            '🔍 DEBUG: idToken (premiers 20 chars): ${idToken.substring(0, idToken.length > 20 ? 20 : idToken.length)}...',
          );
        }

        if (accessToken == null || idToken == null) {
          print(
            '❌ DEBUG: Tokens manquants - accessToken: $accessToken, idToken: $idToken',
          );
          throw Exception('Impossible de récupérer les tokens Google');
        }

        print('✅ AuthRepository: Tokens Google récupérés avec succès');

        // 4. Authentification avec Supabase
        print('🔍 DEBUG: Envoi des tokens à Supabase...');
        final AuthResponse response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        print('🔍 DEBUG: Réponse Supabase reçue');
        print('🔍 DEBUG: response.user != null: ${response.user != null}');

        if (response.user != null) {
          print('🔍 DEBUG: Supabase user.id = ${response.user!.id}');
          print('🔍 DEBUG: Supabase user.email = ${response.user!.email}');
        }

        if (response.user == null) {
          print('❌ DEBUG: Aucun utilisateur dans la réponse Supabase');
          throw Exception('Erreur lors de l\'authentification Supabase');
        }

        print('✅ AuthRepository: Authentification Supabase réussie');

        // 5. Vérifier/Créer le profil utilisateur
        print('🔍 DEBUG: Récupération du profil utilisateur...');
        app_user.User? user = await _getUserProfile(response.user!.id);

        if (user == null) {
          print('📝 AuthRepository: Profil non trouvé, création...');
          user = await _createOAuthUserProfile(
            supabaseId: response.user!.id,
            email: googleUser.email,
            nom: googleUser.displayName?.split(' ').last ?? '',
            prenom: googleUser.displayName?.split(' ').first ?? '',
            photo: googleUser.photoUrl,
          );
          print('✅ DEBUG: Profil créé avec succès');
        } else {
          print('✅ DEBUG: Profil existant trouvé: ${user.fullName}');
        }

        print('✅ AuthRepository: Profil utilisateur prêt');
        return user;
      } catch (tokenError) {
        print(
          '❌ DEBUG: Erreur lors de la récupération des tokens: $tokenError',
        );
        print('❌ DEBUG: Type d\'erreur: ${tokenError.runtimeType}');
        rethrow;
      }
    } catch (e, stackTrace) {
      print('❌ AuthRepository: Erreur Google - $e');
      print('❌ DEBUG: Type d\'erreur: ${e.runtimeType}');
      print('❌ DEBUG: StackTrace: $stackTrace');
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  /// Connexion avec Facebook
  Future<app_user.User?> signInWithFacebook() async {
    try {
      print('🔵 AuthRepository: Début authentification Facebook...');

      // 1. Connexion Facebook
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        print('⚠️ AuthRepository: Connexion Facebook annulée ou échouée');
        return null;
      }

      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        throw Exception('Impossible de récupérer le token Facebook');
      }

      print('✅ AuthRepository: Token Facebook récupéré');

      // 2. Récupérer les données utilisateur Facebook
      final userData = await FacebookAuth.instance.getUserData();
      print('✅ AuthRepository: Données Facebook: ${userData['email']}');

      // 3. Authentification avec Supabase
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken.tokenString,
      );

      if (response.user == null) {
        throw Exception('Erreur lors de l\'authentification Supabase');
      }

      print('✅ AuthRepository: Authentification Supabase réussie');

      // 4. Vérifier/Créer le profil utilisateur
      app_user.User? user = await _getUserProfile(response.user!.id);

      if (user == null) {
        print('📝 AuthRepository: Création du profil utilisateur...');

        // Séparer le nom complet en prénom et nom
        final String fullName = userData['name'] ?? '';
        final List<String> nameParts = fullName.split(' ');
        final String prenom = nameParts.isNotEmpty ? nameParts.first : '';
        final String nom = nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : '';

        user = await _createOAuthUserProfile(
          supabaseId: response.user!.id,
          email: userData['email'] ?? '',
          nom: nom,
          prenom: prenom,
          photo: userData['picture']?['data']?['url'],
        );
      }

      print('✅ AuthRepository: Profil utilisateur prêt');
      return user;
    } catch (e) {
      print('❌ AuthRepository: Erreur Facebook - $e');
      throw Exception('Erreur lors de la connexion Facebook: $e');
    }
  }

  /// Crée un profil utilisateur pour les connexions OAuth (Google, Facebook)
  Future<app_user.User?> _createOAuthUserProfile({
    required String supabaseId,
    required String email,
    required String nom,
    required String prenom,
    String? photo,
  }) async {
    try {
      // 1. Récupérer l'ID du rôle "Visiteur"
      final roleResponse = await _supabase
          .from(SupabaseConfig.rolesTable)
          .select('id')
          .eq('libelle', 'Visiteur')
          .single();

      final visiteurRoleId = roleResponse['id'] as int;

      // 2. Créer le profil dans la table users
      final userProfile = await _supabase
          .from(SupabaseConfig.usersTable)
          .insert({
            'supabase_id': supabaseId,
            'nom': nom.isNotEmpty ? nom : 'Utilisateur',
            'prenom': prenom.isNotEmpty ? prenom : 'Nouveau',
            'email': email,
            'telephone': '', // À compléter par l'utilisateur
            'profession': '', // À compléter par l'utilisateur
            'langue': ['fr'],
            'passions': [],
            'photo': photo,
            'role_id': visiteurRoleId,
            'actif': 'OUI',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return app_user.User.fromJson(userProfile);
    } catch (e) {
      print('❌ AuthRepository: Erreur création profil OAuth - $e');
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }
}
