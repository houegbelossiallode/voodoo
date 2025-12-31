import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/constants/app_strings.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/auth/domain/models/user.dart' as app_user;
import 'package:vodou/features/booking/presentation/pages/my_reservations_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.profile),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            // Utilisateur non connecté
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 80,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Non connecté',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour accéder à votre profil',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.go(AppRouter.login);
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            );
          }

          // Utilisateur connecté - afficher le profil
          return RefreshIndicator(
            onRefresh: () async {
              // Rafraîchir les données du profil
              ref.invalidate(currentUserProvider);
            },
            child: ListView(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryLight.withOpacity(
                          0.2,
                        ),
                        backgroundImage: user.photo != null
                            ? NetworkImage(user.photo!)
                            : null,
                        child: user.photo == null
                            ? Text(
                                '${user.prenom[0]}${user.nom[0]}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.profession,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Membre depuis ${_formatDate(user.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showEditProfileDialog(context, ref, user);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text(AppStrings.editProfile),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Menu Items
                _buildMenuItem(
                  context,
                  ref,
                  Icons.calendar_month,
                  'Mes réservations',
                  () => _navigateToReservations(context),
                ),
                _buildMenuItem(
                  context,
                  ref,
                  Icons.person_outline,
                  AppStrings.personalInfo,
                  () => _showPersonalInfoDialog(context, user),
                ),
                // Afficher "Mes préférences" uniquement pour les visiteurs
                if (user.role?.toLowerCase() == 'visiteur')
                  _buildMenuItem(
                    context,
                    ref,
                    Icons.favorite_outline,
                    'Mes préférences',
                    () => _navigateToPreferences(context),
                  ),
                _buildMenuItem(
                  context,
                  ref,
                  Icons.help_outline,
                  'Aide et support',
                  () => _showHelpDialog(context),
                ),
                _buildMenuItem(
                  context,
                  ref,
                  Icons.info_outline,
                  'À propos',
                  () => _showAboutDialog(context),
                ),
                _buildMenuItem(
                  context,
                  ref,
                  Icons.privacy_tip_outlined,
                  'Confidentialité',
                  () => _showPrivacyDialog(context),
                ),

                const Divider(),

                _buildMenuItem(
                  context,
                  ref,
                  Icons.logout,
                  'Déconnexion',
                  () => _showLogoutConfirmation(context, ref),
                  textColor: AppColors.error,
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Erreur: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(currentUserProvider.notifier).refresh();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildMenuItem(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _navigateToReservations(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyReservationsPage()),
    );
  }

  void _navigateToPreferences(BuildContext context) {
    // Rediriger vers le questionnaire en mode édition (isFirstTime = false)
    context.go(AppRouter.questionnaire, extra: false);
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(currentUserProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(AppRouter.login);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showPersonalInfoDialog(BuildContext context, app_user.User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Nom complet', user.fullName),
              const SizedBox(height: 12),
              _buildInfoRow('Email', user.email),
              const SizedBox(height: 12),
              _buildInfoRow('Téléphone', user.telephone),
              const SizedBox(height: 12),
              _buildInfoRow('Profession', user.profession),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Rôle',
                user.roleId == 1
                    ? 'Visiteur'
                    : user.roleId == 2
                    ? 'Hôte'
                    : 'Administrateur',
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Membre depuis', _formatDate(user.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    app_user.User user,
  ) {
    final prenomController = TextEditingController(text: user.prenom);
    final nomController = TextEditingController(text: user.nom);
    final professionController = TextEditingController(text: user.profession);
    final phoneController = TextEditingController(text: user.telephone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: professionController,
                decoration: const InputDecoration(
                  labelText: 'Profession',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validation basique
              if (prenomController.text.trim().isEmpty ||
                  nomController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le prénom et le nom sont obligatoires'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              // Validation et récupération du navigator avant les opérations async
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              // Fermer le dialogue
              navigator.pop();

              // Afficher un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                print('🔄 Début de la mise à jour du profil...');
                print('   Prénom: ${prenomController.text.trim()}');
                print('   Nom: ${nomController.text.trim()}');
                print('   Profession: ${professionController.text.trim()}');
                print('   Téléphone: ${phoneController.text.trim()}');

                // Mettre à jour le profil
                await ref
                    .read(currentUserProvider.notifier)
                    .updateProfile(
                      prenom: prenomController.text.trim(),
                      nom: nomController.text.trim(),
                      profession: professionController.text.trim().isEmpty
                          ? null
                          : professionController.text.trim(),
                      telephone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                    );

                print('✅ Profil mis à jour avec succès');

                // Fermer l'indicateur de chargement
                print('🔄 Fermeture de l\'indicateur de chargement');
                navigator.pop();

                // Afficher un message de succès
                print('🔄 Affichage du message de succès');
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('✅ Profil mis à jour avec succès'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e, stackTrace) {
                print('❌ Erreur lors de la mise à jour du profil: $e');
                print('📋 Stack trace: $stackTrace');

                // Fermer l'indicateur de chargement
                print('🔄 Fermeture de l\'indicateur de chargement (erreur)');
                navigator.pop();

                // Afficher un message d'erreur
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('❌ Erreur: ${e.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide et support'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('📧 Email: support@vodouhost.com'),
              SizedBox(height: 8),
              Text('📞 Téléphone: +229 XX XX XX XX'),
              SizedBox(height: 8),
              Text('🕐 Horaires: Lun-Ven 9h-18h'),
              SizedBox(height: 16),
              Text(
                'FAQ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Comment réserver un logement ?'),
              Text('• Comment contacter un hôte ?'),
              Text('• Comment participer aux rituels ?'),
              Text('• Politique d\'annulation'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vodoo Host',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text('Version 1.0.0'),
              SizedBox(height: 16),
              Text(
                'Plateforme d\'hébergement chez l\'habitant durant la fête du Vodoun à Ouidah, Bénin.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Découvrez la culture vodoun authentique en séjournant chez des hôtes locaux et en participant à des rituels traditionnels.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '© 2026 Vodoo Host. Tous droits réservés.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidentialité'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Politique de confidentialité',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Vos données personnelles',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Nous collectons uniquement les informations nécessaires pour vous offrir nos services : nom, email, téléphone, préférences culturelles.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'Utilisation des données',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Vos données sont utilisées pour faciliter les réservations, améliorer votre expérience et vous proposer des recommandations personnalisées.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'Sécurité',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Vos données sont stockées de manière sécurisée et ne sont jamais partagées avec des tiers sans votre consentement.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
