import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';

/// Page de connexion simple avec email et mot de passe
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    print('🔐 Tentative de connexion avec: ${_emailController.text.trim()}');

    try {
      await ref
          .read(currentUserProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      print('✅ Connexion réussie !');

      if (mounted) {
        _handleSuccessfulLogin();
      }
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      await ref.read(currentUserProvider.notifier).signInWithGoogle();
      if (mounted) {
        _handleSuccessfulLogin();
      }
    } catch (e) {
      print('❌ Erreur Google: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Google: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    // Récupérer l'utilisateur connecté
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      print('⚠️ Utilisateur non trouvé après connexion');
      context.go(AppRouter.festivalSelection, extra: true);
      return;
    }

    // Vérifier le rôle de l'utilisateur
    final userRole = user.role?.toLowerCase() ?? '';
    print('👤 Rôle utilisateur: $userRole');

    // Seuls les visiteurs passent par le questionnaire
    if (userRole == 'visiteur') {
      try {
        print('🔍 Vérification des préférences utilisateur...');
        final hasCompleted = await ref.read(
          hasCompletedQuestionnaireProvider.future,
        );

        print('📊 hasCompleted = $hasCompleted');

        if (!hasCompleted) {
          print('🎉 Redirection vers festival-selection (isFirstTime=true)');
          context.go(AppRouter.festivalSelection, extra: true);
        } else {
          print('🎉 Redirection vers festival-selection (isFirstTime=false)');
          context.go(AppRouter.festivalSelection, extra: false);
        }
      } catch (e) {
        print('⚠️ Erreur vérification préférences: $e');
        print(
          '🎉 Redirection vers festival-selection par défaut (isFirstTime=true)',
        );
        context.go(AppRouter.festivalSelection, extra: true);
      }
    } else {
      // Hôtes, administrateurs, etc. vont directement à la sélection de festival
      print(
        '🎉 Redirection vers festival-selection ($userRole, isFirstTime=false)',
      );
      context.go(AppRouter.festivalSelection, extra: false);
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
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Email invalide';
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
                        return 'Veuillez entrer votre mot de passe';
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
