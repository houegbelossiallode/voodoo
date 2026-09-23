import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/core/utils/auth_error_formatter.dart';
import 'package:vodou/features/auth/domain/models/role.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/auth/presentation/providers/first_time_visitor_provider.dart';
import 'package:vodou/features/auth/presentation/widgets/google_role_selection_dialog.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Page de connexion simple avec email et mot de passe
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNewOAuthUser();
    });
  }

  /// Vérifie si un utilisateur Supabase Auth est déjà connecté mais sans profil local
  Future<void> _checkPendingNewOAuthUser() async {
    final supabaseUser = SupabaseService.instance.currentUser;
    if (supabaseUser != null) {
      final userProfile = await ref
          .read(authRepositoryProvider)
          .getCurrentUser();
      if (userProfile == null && mounted) {
        AppLogger.d(
          '🔍 Auth active sans profil local, affichage du dialogue de rôle...',
        );
        final String email = supabaseUser.email ?? '';
        final String metaGivenName =
            (supabaseUser.userMetadata?['given_name'] as String? ?? '').trim();
        final String metaFamilyName =
            (supabaseUser.userMetadata?['family_name'] as String? ?? '').trim();
        final String fullName =
            (supabaseUser.userMetadata?['full_name'] ??
                    supabaseUser.userMetadata?['name'] ??
                    '')
                .toString()
                .trim();

        String prenom = metaGivenName;
        String nom = metaFamilyName;

        if (prenom.isEmpty || nom.isEmpty) {
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

        final String? photo =
            supabaseUser.userMetadata?['avatar_url'] ??
            supabaseUser.userMetadata?['picture'];

        final Role? selectedRole = await GoogleRoleSelectionDialog.show(
          context,
          userName: prenom.isNotEmpty ? prenom : nom,
        );

        if (selectedRole != null && mounted) {
          if (selectedRole.libelle.toLowerCase() == 'visiteur') {
            ref.read(justSignedUpAsVisitorProvider.notifier).state = true;
          }
          await ref
              .read(currentUserProvider.notifier)
              .completeOAuthProfile(
                supabaseId: supabaseUser.id,
                email: email,
                nom: nom,
                prenom: prenom,
                roleId: selectedRole.id,
                photo: photo,
              );
          if (mounted) {
            _handleSuccessfulLogin();
          }
        } else if (mounted) {
          await ref.read(currentUserProvider.notifier).signOut();
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      AppLogger.d('📝 Début de la connexion...');
      await ref
          .read(currentUserProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      AppLogger.d('✅ Connexion réussie!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connexion réussie ! Bienvenue.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        await _handleSuccessfulLogin();
      }
    } catch (e) {
      AppLogger.e('❌ Erreur de connexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AuthErrorFormatter.format(e),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(currentUserProvider.notifier)
          .signInWithGoogle();

      if (result == null) {
        // Annulé par l'utilisateur au niveau Google
        return;
      }

      if (result.isNewUser) {
        if (mounted) {
          // Arrêter le spinner de chargement pour afficher clairement le dialogue
          setState(() => _isLoading = false);

          // Afficher le dialogue de choix de rôle pour le premier profil Google
          final Role? selectedRole = await GoogleRoleSelectionDialog.show(
            context,
            userName: result.prenom ?? result.nom ?? '',
          );

          if (selectedRole != null && mounted) {
            setState(() => _isLoading = true);

            // Marquer comme visiteur si le rôle est visiteur (pour le questionnaire)
            if (selectedRole.libelle.toLowerCase() == 'visiteur') {
              ref.read(justSignedUpAsVisitorProvider.notifier).state = true;
            }

            // Enregistrer le profil complet dans Supabase
            await ref
                .read(currentUserProvider.notifier)
                .completeOAuthProfile(
                  supabaseId: result.supabaseId!,
                  email: result.email!,
                  nom: result.nom!,
                  prenom: result.prenom!,
                  roleId: selectedRole.id,
                  photo: result.photo,
                );

            if (mounted) {
              await _handleSuccessfulLogin();
            }
          } else if (mounted) {
            // Si l'utilisateur ferme/annule le dialogue de rôle
            await ref.read(currentUserProvider.notifier).signOut();
          }
        }
      } else {
        // Utilisateur existant : redirection directe sans dialogue de rôle
        if (mounted) {
          await _handleSuccessfulLogin();
        }
      }
    } catch (e) {
      AppLogger.e('❌ Erreur Google: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AuthErrorFormatter.format(e),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSuccessfulLogin() async {
    if (!mounted) return;

    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      AppLogger.w('⚠️ Utilisateur non trouvé après connexion');
      if (mounted) {
        context.go(AppRouter.festivalSelection, extra: true);
      }
      return;
    }

    // Vérifier le rôle de l'utilisateur
    final userRole = user.role?.toLowerCase() ?? '';
    AppLogger.d('👤 Rôle utilisateur: $userRole');

    // Seuls les visiteurs passent par le questionnaire
    if (userRole == 'visiteur') {
      try {
        AppLogger.d('🔍 Vérification des préférences utilisateur...');
        final hasCompleted = await ref.read(
          hasCompletedQuestionnaireProvider.future,
        );

        AppLogger.d('📊 hasCompleted = $hasCompleted');

        if (!mounted) return;

        if (!hasCompleted) {
          AppLogger.d(
            '🎉 Redirection vers festival-selection (isFirstTime=true)',
          );
          context.go(AppRouter.festivalSelection, extra: true);
        } else {
          AppLogger.d(
            '🎉 Redirection vers festival-selection (isFirstTime=false)',
          );
          context.go(AppRouter.festivalSelection, extra: false);
        }
      } catch (e) {
        AppLogger.w('⚠️ Erreur vérification préférences: $e');
        if (mounted) {
          AppLogger.d(
            '🎉 Redirection vers festival-selection par défaut (isFirstTime=true)',
          );
          context.go(AppRouter.festivalSelection, extra: true);
        }
      }
    } else {
      // Hôtes, administrateurs, etc. vont directement à la sélection de festival
      if (mounted) {
        AppLogger.d(
          '🎉 Redirection vers festival-selection ($userRole, isFirstTime=false)',
        );
        context.go(AppRouter.festivalSelection, extra: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo et titre
                  Image.asset(
                    'assets/logos/logo_2.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.home_outlined,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vodoo Host',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous à votre compte',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Champ Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'votre@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir votre adresse email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Veuillez entrer une adresse email valide (ex: nom@domaine.com)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Mot de passe
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signIn(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir votre mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.push(AppRouter.forgotPassword);
                      },
                      child: Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton de connexion
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),

                  // Séparateur "Ou continuer avec"
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.greyLight)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ou continuer avec',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.greyLight)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouton OAuth (Google uniquement)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: Image.asset(
                      'assets/icons/google.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.g_mobiledata, size: 24),
                    ),
                    label: const Text('Continuer avec Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.greyLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Lien vers inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push(AppRouter.signup);
                        },
                        child: Text(
                          'S\'inscrire',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
