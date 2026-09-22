import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/domain/models/user.dart' as app_user;
import 'package:vodou/features/auth/domain/models/role.dart';

/// Repository pour gérer l'authentification avec Supabase
class AuthRepository {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Récupère tous les rôles actifs
  Future<List<Role>> getActiveRoles() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.rolesTable)
          .select()
          .eq('actif', 'OUI')
          .order('libelle');

      return (response as List)
          .map((json) => Role.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rôles: $e');
    }
  }

  /// Inscription avec email et mot de passe
  /// Stocke les données dans user_metadata pour création du profil après confirmation email
  Future<app_user.User?> signUpWithEmail({
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
      // 1. Créer le compte Supabase Auth avec les métadonnées
      print(' Inscription avec confirmation email...');
      print('   - Email: $email');
      print('   - Nom: $nom, Prénom: $prenom');
      print('   - Rôle ID: $roleId');

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        // Utiliser l'URL par défaut de Supabase (navigateur web)
        // L'app détectera automatiquement la connexion via le listener d'auth
        data: {
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'profession': profession,
          'role_id': roleId,
          'langue': langue ?? ['fr'],
          'passions': passions ?? [],
          'bio': bio ?? '',
        },
      );

      if (authResponse.user == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // Vérifier si l'email existe déjà (compte déjà créé mais non confirmé)
      if (authResponse.user!.identities != null && authResponse.user!.identities!.isEmpty) {
        print('⚠️ Email déjà existant mais non confirmé');
        throw Exception('Cette adresse email est déjà utilisée mais le compte n\'a pas été confirmé. Veuillez vérifier votre boîte mail pour confirmer votre compte, ou utilisez une autre adresse email.');
      }

      print(' Compte créé avec succès - En attente de confirmation email');
      print('   - Données stockées dans user_metadata');
      print('   - URL de redirection: vodoohost://auth/callback');

      // Si la confirmation email est désactivée (mode développement), créer le profil immédiatement
      if (SupabaseConfig.disableEmailConfirmation) {
        print(' Confirmation email désactivée - Création immédiate du profil');
        final user = await _createProfileFromMetadata(authResponse.user!.id);
        return user;
      }

      return null;
    } on AuthException catch (e) {
      print('❌ Erreur Supabase lors de l\'inscription');
      print('   Message: ${e.message}');
      print('   Status code: ${e.statusCode}');
      
      // Personnaliser les messages d'erreur selon le type d'erreur
      String errorMessage;
      
      if (e.message.contains('User already registered') || 
          e.message.contains('already registered') ||
          e.message.contains('already exists') ||
          e.message.contains('user_already_exists') ||
          e.message.contains('duplicate') ||
          e.message.contains('email_already_in_use')) {
        errorMessage = 'Cette adresse email est déjà utilisée. Veuillez vous connecter ou utiliser une autre adresse email.';
      } else if (e.message.contains('Invalid email') || e.message.contains('invalid_email')) {
        errorMessage = 'L\'adresse email n\'est pas valide. Veuillez vérifier votre saisie.';
      } else if (e.message.contains('Password') || e.message.contains('password')) {
        errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.';
      } else if (e.message.contains('rate limit') || e.message.contains('too many')) {
        errorMessage = 'Trop de tentatives d\'inscription. Veuillez réessayer dans quelques minutes.';
      } else if (e.statusCode == 429) {
        errorMessage = 'Trop de tentatives. Veuillez attendre quelques instants avant de réessayer.';
      } else if (e.statusCode == 400) {
        errorMessage = e.message.isNotEmpty ? e.message : 'Une erreur est survenue lors de l\'inscription. Veuillez réessayer.';
      } else {
        errorMessage = 'Une erreur est survenue lors de l\'inscription. Veuillez réessayer.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Erreur inattendue lors de l\'inscription: $e');
      print('   Type: ${e.runtimeType}');
      
      // Si c'est une Exception personnalisée, on la rethrow telle quelle
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception('Une erreur inattendue est survenue. Veuillez réessayer.');
    }
  }

  /// Connexion avec email et mot de passe
  Future<app_user.User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print(' AuthRepository: Appel Supabase signInWithPassword...');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print(' AuthRepository: Réponse Supabase reçue');
      print(' User ID: ${response.user?.id}');
      print('📡 AuthRepository: Réponse Supabase reçue');
      print('📡 User ID: ${response.user?.id}');

      if (response.user != null) {
        print('📡 AuthRepository: Récupération du profil utilisateur...');
        final user = await _getUserProfile(response.user!.id);
        
        // Si le profil n'existe pas, essayer de le créer depuis user_metadata
        if (user == null) {
          print('📝 Profil non trouvé - Tentative de création depuis user_metadata...');
          final createdUser = await _createProfileFromMetadata(response.user!.id);
          if (createdUser != null) {
            print('✅ Profil créé depuis user_metadata');
            return createdUser;
          }
        }
        
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

  /// Crée le profil utilisateur depuis les user_metadata de Supabase Auth
  Future<app_user.User?> _createProfileFromMetadata(String supabaseId) async {
    try {
      // Récupérer l'utilisateur courant pour accéder aux métadonnées
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('⚠️ Aucun utilisateur courant trouvé');
        return null;
      }

      final metadata = currentUser.userMetadata;
      if (metadata == null) {
        print('⚠️ Aucune métadonnée trouvée pour cet utilisateur');
        return null;
      }

      print('📝 Métadonnées trouvées: $metadata');

      // Extraire les données des métadonnées
      final nom = metadata['nom'] as String? ?? '';
      final prenom = metadata['prenom'] as String? ?? '';
      final telephone = metadata['telephone'] as String? ?? '';
      final profession = metadata['profession'] as String? ?? '';
      final roleId = metadata['role_id'] as int?;
      final langue = metadata['langue'] as List<dynamic>?;
      final passions = metadata['passions'] as List<dynamic>?;
      final bio = metadata['bio'] as String?;
      final email = currentUser.email ?? '';

      if (roleId == null) {
        print('⚠️ role_id manquant dans les métadonnées');
        return null;
      }

      // Créer le profil dans la table users
      final userProfile = await _supabase
          .from(SupabaseConfig.usersTable)
          .insert({
            'supabase_id': supabaseId,
            'nom': nom.isNotEmpty ? nom : 'Utilisateur',
            'prenom': prenom.isNotEmpty ? prenom : 'Nouveau',
            'email': email,
            'telephone': telephone,
            'profession': profession,
            'langue': langue ?? ['fr'],
            'passions': passions ?? [],
            'bio': bio,
            'role_id': roleId,
            'actif': 'OUI',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            role:${SupabaseConfig.rolesTable}!role_id(id, libelle)
          ''')
          as List<dynamic>;

      if (userProfile.isEmpty) {
        print('⚠️ Erreur lors de la création du profil');
        return null;
      }

      final profileData = userProfile.first as Map<String, dynamic>;
      print('✅ Profil créé avec succès depuis user_metadata');
      return app_user.User.fromJson(profileData);
    } catch (e) {
      print('❌ Erreur lors de la création du profil depuis metadata: $e');
      return null;
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
      // 1. Déconnecter Supabase EN PREMIER pour invalider la session immédiatement
      await _supabase.auth.signOut();
      print('✅ Session Supabase fermée');

      // 2. Déconnecter Google Sign-In localement (instantané)
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: SupabaseConfig.googleClientId,
        );
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (e) {
        print('⚠️ Erreur déconnexion Google: $e');
      }

      // 3. Déconnecter Facebook Auth si actif
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        print('⚠️ Erreur déconnexion Facebook: $e');
      }

      print('✅ Déconnexion complète effectuée');
    } catch (e) {
      print('⚠️ Erreur lors de la déconnexion: $e');
    }
  }

  /// Récupère le profil utilisateur depuis la base de données par supabase_id ou email
  Future<app_user.User?> _getUserProfile(String supabaseId, {String? email}) async {
    try {
      print('🔍 Recherche du profil pour supabase_id: $supabaseId ${email != null ? "ou email: $email" : ""}');

      // 1. Chercher d'abord par supabase_id
      var response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('''
            *,
            role:${SupabaseConfig.rolesTable}!role_id(id, libelle)
          ''')
          .eq('supabase_id', supabaseId)
          .eq('actif', 'OUI') as List<dynamic>;

      // 2. Si non trouvé et email fourni, chercher par email
      if (response.isEmpty && email != null && email.isNotEmpty) {
        print('🔍 Aucun profil trouvé avec supabase_id, recherche par email: $email');
        response = await _supabase
            .from(SupabaseConfig.usersTable)
            .select('''
              *,
              role:${SupabaseConfig.rolesTable}!role_id(id, libelle)
            ''')
            .eq('email', email)
            .eq('actif', 'OUI') as List<dynamic>;

        // Si le profil existe par email, on met à jour son supabase_id
        if (response.isNotEmpty) {
          final existingProfile = response.first as Map<String, dynamic>;
          print('📝 Mise à jour du supabase_id pour l\'utilisateur existant #${existingProfile['id']}...');
          await _supabase
              .from(SupabaseConfig.usersTable)
              .update({'supabase_id': supabaseId})
              .eq('id', existingProfile['id']);
          existingProfile['supabase_id'] = supabaseId;
        }
      }

      print('🔍 Réponse brute: $response');

      // Vérifier si la réponse contient des données
      if (response.isEmpty) {
        print('⚠️ Aucun profil trouvé pour cet utilisateur');
        return null;
      }

      // Prendre le premier élément de la liste
      final profileData = response.first as Map<String, dynamic>;
      print('✅ Profil trouvé: ${profileData['prenom']} ${profileData['nom']}');

      return app_user.User.fromJson(profileData);
    } catch (e) {
      // Si le profil n'existe pas encore
      print('⚠️ Erreur lors de la recherche du profil: $e');
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
      print('📝 AuthRepository.updateUserProfile: ID=#$userId, photo=$photo');
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
          .eq('id', userId)
          .select('''
            *,
            role:${SupabaseConfig.rolesTable}!role_id(libelle)
          ''')
          .single();

      print('✅ AuthRepository.updateUserProfile: Profil mis à jour en BDD avec succès!');
      return app_user.User.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ AuthRepository.updateUserProfile ERREUR BDD: $e');
      print('❌ StackTrace: $stackTrace');
      throw Exception('Erreur lors de la mise à jour BDD (users.photo): $e');
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

  Future<GoogleAuthResult?> signInWithGoogle() async {
    try {
      print('🔵 AuthRepository: Début authentification Google...');
      print('🔍 DEBUG: Web Client ID = ${SupabaseConfig.googleClientId}');
      print(
        '🔍 DEBUG: Android Client ID = ${SupabaseConfig.googleAndroidClientId}',
      );

      // 1. Initialiser Google Sign In
      print('🔍 DEBUG: Initialisation GoogleSignIn...');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.googleClientId,
        scopes: ['email', 'profile', 'openid'],
      );
      print('✅ DEBUG: GoogleSignIn initialisé avec Web Client ID');

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

        if (response.user == null) {
          print('❌ DEBUG: Aucun utilisateur dans la réponse Supabase');
          throw Exception('Erreur lors de l\'authentification Supabase');
        }

        print('✅ AuthRepository: Authentification Supabase réussie');

        // 5. Vérifier/Créer le profil utilisateur
        print('🔍 DEBUG: Récupération du profil utilisateur...');
        app_user.User? user = await _getUserProfile(
          response.user!.id,
          email: googleUser.email,
        );

        if (user == null) {
          print('📝 AuthRepository: Profil non trouvé -> Nouvel utilisateur Google');

          final String metaGivenName =
              (response.user?.userMetadata?['given_name'] as String? ?? '').trim();
          final String metaFamilyName =
              (response.user?.userMetadata?['family_name'] as String? ?? '').trim();

          String prenom = metaGivenName;
          String nom = metaFamilyName;

          if (prenom.isEmpty || nom.isEmpty) {
            final String fullName = (googleUser.displayName ??
                    response.user?.userMetadata?['full_name'] ??
                    response.user?.userMetadata?['name'] ??
                    '')
                .toString()
                .trim();

            if (fullName.isNotEmpty) {
              final List<String> nameParts = fullName.split(RegExp(r'\s+'));
              if (prenom.isEmpty && nameParts.isNotEmpty) {
                prenom = nameParts.first;
              }
              if (nom.isEmpty) {
                nom = nameParts.length > 1
                    ? nameParts.sublist(1).join(' ')
                    : prenom;
              }
            }
          }

          if (prenom.isEmpty) prenom = 'Utilisateur';
          if (nom.isEmpty) nom = prenom;

          print('👤 Données Google extraites - Prénom: "$prenom", Nom: "$nom"');

          return GoogleAuthResult(
            isNewUser: true,
            supabaseId: response.user!.id,
            email: googleUser.email,
            nom: nom,
            prenom: prenom,
            photo: googleUser.photoUrl ?? response.user?.userMetadata?['avatar_url'],
          );
        } else {
          print('✅ DEBUG: Profil existant trouvé: ${user.fullName}');
          return GoogleAuthResult(
            user: user,
            isNewUser: false,
          );
        }
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

        user = await createOAuthUserProfile(
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
  Future<app_user.User?> createOAuthUserProfile({
    required String supabaseId,
    required String email,
    required String nom,
    required String prenom,
    int? roleId,
    String? photo,
  }) async {
    try {
      int targetRoleId;
      if (roleId != null) {
        targetRoleId = roleId;
      } else {
        // 1. Récupérer l'ID du rôle "Visiteur" par défaut si non spécifié
        final roleResponse = await _supabase
            .from(SupabaseConfig.rolesTable)
            .select('id')
            .eq('libelle', 'Visiteur')
            .single();

        targetRoleId = roleResponse['id'] as int;
      }

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
            'role_id': targetRoleId,
            'actif': 'OUI',
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

/// Modèle représentant le résultat d'une tentative d'authentification Google OAuth
class GoogleAuthResult {
  final app_user.User? user;
  final bool isNewUser;
  final String? supabaseId;
  final String? email;
  final String? nom;
  final String? prenom;
  final String? photo;

  GoogleAuthResult({
    this.user,
    required this.isNewUser,
    this.supabaseId,
    this.email,
    this.nom,
    this.prenom,
    this.photo,
  });
}
