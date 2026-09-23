import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/constants/app_strings.dart';
import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/file_upload_service.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/auth/presentation/providers/role_provider.dart';
import 'package:vodou/features/auth/domain/models/user.dart' as app_user;
import 'package:vodou/features/booking/presentation/pages/my_reservations_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/core/error/error_mapper.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.profile,
        showBackButton: false,
      ),
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
                      Stack(
                        children: [
                          _buildProfileAvatar(user),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  _updateProfilePhoto(context, ref, user),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, child) {
                          // 1. Si le libellé a été directement extrait via la relation Supabase (users.role_id -> roles.id)
                          if (user.role != null &&
                              user.role!.isNotEmpty &&
                              int.tryParse(user.role!) == null) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.role!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }

                          // 2. Sinon, résoudre dynamiquement par correspondance role_id dans la table roles
                          final rolesAsync = ref.watch(rolesProvider);
                          final String dynamicRoleLabel = rolesAsync.when(
                            data: (roles) {
                              final match = roles.where(
                                (r) => r.id == user.roleId,
                              );
                              return match.isNotEmpty
                                  ? match.first.libelle
                                  : '';
                            },
                            loading: () => 'Chargement...',
                            error: (_, __) => '',
                          );

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              dynamicRoleLabel.isNotEmpty
                                  ? dynamicRoleLabel
                                  : 'Visiteur',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (user.profession.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.profession,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textHint),
                        ),
                      ],
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
                ErrorMapper.toMessage(error),
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

  Widget _buildProfileAvatar(app_user.User user) {
    final hasPhoto = user.photo != null && user.photo!.trim().isNotEmpty;
    final photoUrl = hasPhoto ? user.photo!.trim() : '';

    Widget fallbackInitials = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${user.prenom.isNotEmpty ? user.prenom[0] : ""}${user.nom.isNotEmpty ? user.nom[0] : ""}'
            .toUpperCase(),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );

    if (!hasPhoto) {
      return fallbackInitials;
    }

    final bool isNetwork =
        photoUrl.startsWith('http://') || photoUrl.startsWith('https://');

    String cleanFilePath = photoUrl;
    if (cleanFilePath.startsWith('file://')) {
      try {
        cleanFilePath = Uri.parse(cleanFilePath).toFilePath();
      } catch (_) {
        cleanFilePath = cleanFilePath.replaceFirst('file://', '');
      }
    }

    final localFile = File(cleanFilePath);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight.withValues(alpha: 0.2),
      ),
      child: ClipOval(
        child: isNetwork
            ? Image.network(
                photoUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 100,
                    height: 100,
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  AppLogger.e(
                    '❌ Erreur chargement photo réseau ($photoUrl): $error',
                  );
                  return fallbackInitials;
                },
              )
            : (localFile.existsSync()
                  ? Image.file(
                      localFile,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        AppLogger.e(
                          '❌ Erreur chargement photo fichier ($cleanFilePath): $error',
                        );
                        return fallbackInitials;
                      },
                    )
                  : fallbackInitials),
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
    // Naviguer vers le questionnaire en mode édition (isFirstTime = false)
    context.push(AppRouter.questionnaire, extra: false);
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
              await ref.read(currentUserProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRouter.login);
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

  void _updateProfilePhoto(
    BuildContext context,
    WidgetRef ref,
    app_user.User user,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Changer la photo de profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadImage(
                      context,
                      ref,
                      ImageSource.gallery,
                      messenger,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                  title: const Text('Prendre une photo'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadImage(
                      context,
                      ref,
                      ImageSource.camera,
                      messenger,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link, color: AppColors.primary),
                  title: const Text('Entrer l\'URL d\'une image'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showUrlInputDialog(context, ref, user, messenger);
                  },
                ),
                if (user.photo != null && user.photo!.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Supprimer la photo de profil',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _showDeletePhotoConfirmation(context, ref, messenger);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeletePhotoConfirmation(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) {
    final user = ref.read(currentUserProvider).value;
    final currentPhotoUrl = user?.photo ?? '';

    if (currentPhotoUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Supprimer la photo'),
              content: isDeleting
                  ? const Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Expanded(
                          child: Text('Suppression de la photo de profil...'),
                        ),
                      ],
                    )
                  : const Text(
                      'Êtes-vous sûr de vouloir supprimer votre photo de profil ?',
                    ),
              actions: isDeleting
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isDeleting = true;
                          });

                          try {
                            final fileUploadService = FileUploadService(
                              SupabaseService.instance,
                            );
                            await fileUploadService.deleteProfilePhoto(
                              currentPhotoUrl,
                            );

                            await ref
                                .read(currentUserProvider.notifier)
                                .updateProfile(photo: '');

                            // `dialogContext` traverse un await (VUL-16).
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '✅ Photo de profil supprimée avec succès',
                                ),
                                backgroundColor: AppColors.success,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '❌ Erreur lors de la suppression: $e',
                                ),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
    ScaffoldMessengerState messenger,
  ) async {
    debugPrint('📸 [PROFILE] _pickAndUploadImage démarré (source: $source)');

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint(
          '⚠️ [PROFILE] Aucun fichier sélectionné par l\'utilisateur.',
        );
        return;
      }

      bool dialogShown = false;
      if (context.mounted) {
        dialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(child: Text('Envoi de la photo de profil...')),
              ],
            ),
          ),
        );
      }

      String cleanLocalPath = pickedFile.path;
      if (cleanLocalPath.startsWith('file://')) {
        try {
          cleanLocalPath = Uri.parse(cleanLocalPath).toFilePath();
        } catch (_) {
          cleanLocalPath = cleanLocalPath.replaceFirst('file://', '');
        }
      }

      final fileUploadService = FileUploadService(SupabaseService.instance);
      final String publicUrl = await fileUploadService.uploadFile(
        file: File(cleanLocalPath),
        bucket: SupabaseConfig.userPhotosBucket,
        folder: 'avatars',
      );

      await ref
          .read(currentUserProvider.notifier)
          .updateProfile(photo: publicUrl);

      debugPrint(
        '✅ [PROFILE] Colonne photo mise à jour avec succès dans la table users!',
      );

      if (dialogShown && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Photo de profil mise à jour avec succès'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ [PROFILE] ERREUR DANS _pickAndUploadImage: $e');
      debugPrint('❌ [PROFILE] StackTrace: $stack');
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la mise à jour de la photo: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  void _showUrlInputDialog(
    BuildContext context,
    WidgetRef ref,
    app_user.User user,
    ScaffoldMessengerState messenger,
  ) {
    final photoUrlController = TextEditingController(text: user.photo ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('URL de la photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez l\'URL de votre nouvelle photo de profil :',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: photoUrlController,
              decoration: const InputDecoration(
                labelText: 'URL (.png, .jpg, .jpeg)',
                hintText: 'https://exemple.com/photo.jpg',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhoto = photoUrlController.text.trim();

              if (newPhoto.isNotEmpty) {
                final lowerUrl = newPhoto.toLowerCase();
                final bool isValidExtension =
                    lowerUrl.endsWith('.png') ||
                    lowerUrl.endsWith('.jpg') ||
                    lowerUrl.endsWith('.jpeg') ||
                    lowerUrl.contains('.png?') ||
                    lowerUrl.contains('.jpg?') ||
                    lowerUrl.contains('.jpeg?');

                if (!isValidExtension) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        '❌ L\'URL doit pointer vers une image PNG, JPG ou JPEG.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
              }

              Navigator.pop(dialogContext);

              try {
                await ref
                    .read(currentUserProvider.notifier)
                    .updateProfile(photo: newPhoto.isEmpty ? null : newPhoto);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('✅ Photo de profil mise à jour'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('❌ Erreur lors de la mise à jour: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
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
              _buildInfoRow(
                'Téléphone',
                user.telephone.isNotEmpty ? user.telephone : 'Non renseigné',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Profession',
                user.profession.isNotEmpty ? user.profession : 'Non renseignée',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Rôle',
                user.role ??
                    (user.roleId == 1
                        ? 'Visiteur'
                        : user.roleId == 2
                        ? 'Hôte'
                        : 'Administrateur'),
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
                AppLogger.d('🔄 Début de la mise à jour du profil...');
                AppLogger.d('   Prénom: ${prenomController.text.trim()}');
                AppLogger.d('   Nom: ${nomController.text.trim()}');
                AppLogger.d(
                  '   Profession: ${professionController.text.trim()}',
                );
                AppLogger.d('   Téléphone: ${phoneController.text.trim()}');

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

                AppLogger.d('✅ Profil mis à jour avec succès');

                // Fermer l'indicateur de chargement
                AppLogger.d('🔄 Fermeture de l\'indicateur de chargement');
                navigator.pop();

                // Afficher un message de succès
                AppLogger.d('🔄 Affichage du message de succès');
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('✅ Profil mis à jour avec succès'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e, stackTrace) {
                AppLogger.e('❌ Erreur lors de la mise à jour du profil: $e');
                AppLogger.d('📋 Stack trace: $stackTrace');

                // Fermer l'indicateur de chargement
                AppLogger.d(
                  '🔄 Fermeture de l\'indicateur de chargement (erreur)',
                );
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
