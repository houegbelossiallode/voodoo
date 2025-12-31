import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/auth/presentation/providers/role_provider.dart';
import 'package:vodou/features/auth/presentation/providers/first_time_visitor_provider.dart';
import 'package:vodou/features/auth/domain/models/role.dart';

/// Page d'inscription avec email et mot de passe
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _professionController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Role? _selectedRole;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier que les mots de passe correspondent
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier qu'un rôle est sélectionné
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un rôle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📝 Début de l\'inscription...');

      // Marquer si c'est un visiteur pour le questionnaire
      final isVisitor = _selectedRole!.libelle.toLowerCase() == 'visiteur';
      if (isVisitor) {
        ref.read(justSignedUpAsVisitorProvider.notifier).state = true;
        print('🎯 Marqué comme nouveau visiteur pour questionnaire');
      }

      await ref
          .read(currentUserProvider.notifier)
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            telephone: _telephoneController.text.trim(),
            profession: _professionController.text.trim(),
            roleId: _selectedRole!.id,
            langue: ['fr'],
          );

      print('✅ Inscription réussie!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        // Le router va gérer la redirection automatiquement
        print('🔄 Attente de la redirection automatique par le router...');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Créer un compte'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Icon(
                  Icons.person_add_outlined,
                  size: 60,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Rejoignez Vodoo Host',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Prénom
                TextFormField(
                  controller: _prenomController,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    hintText: 'John',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre prénom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nom
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Doe',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
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

                // Téléphone
                TextFormField(
                  controller: _telephoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '+22997123456',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Sélecteur de rôle
                Consumer(
                  builder: (context, ref, child) {
                    final rolesAsync = ref.watch(rolesProvider);

                    return rolesAsync.when(
                      data: (roles) {
                        return DropdownButtonFormField<Role>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Rôle *',
                            hintText: 'Sélectionnez votre rôle',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: roles.map((role) {
                            return DropdownMenuItem<Role>(
                              value: role,
                              child: Text(role.libelle),
                            );
                          }).toList(),
                          onChanged: (Role? newValue) {
                            setState(() {
                              _selectedRole = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un rôle';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => TextFormField(
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Rôle',
                          hintText: 'Chargement des rôles...',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      error: (error, stack) => TextFormField(
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Rôle',
                          hintText: 'Erreur de chargement',
                          prefixIcon: const Icon(Icons.error_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Profession
                TextFormField(
                  controller: _professionController,
                  decoration: InputDecoration(
                    labelText: 'Profession',
                    hintText: 'Développeur',
                    prefixIcon: const Icon(Icons.work_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre profession';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mot de passe
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
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmation mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signUp(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Bouton d'inscription
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
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
                          'Créer mon compte',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Lien vers connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Vous avez déjà un compte ? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Se connecter',
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
    );
  }
}
