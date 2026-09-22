import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/auth/domain/models/role.dart';
import 'package:vodou/features/auth/presentation/providers/role_provider.dart';

/// Dialogue interactif permettant à un nouvel utilisateur Google de choisir son rôle
class GoogleRoleSelectionDialog extends ConsumerStatefulWidget {
  final String userName;

  const GoogleRoleSelectionDialog({
    Key? key,
    required this.userName,
  }) : super(key: key);

  static Future<Role?> show(BuildContext context, {required String userName}) {
    return showDialog<Role>(
      context: context,
      barrierDismissible: false, // Empêcher la fermeture sans choix de rôle
      builder: (context) => GoogleRoleSelectionDialog(userName: userName),
    );
  }

  @override
  ConsumerState<GoogleRoleSelectionDialog> createState() =>
      _GoogleRoleSelectionDialogState();
}

class _GoogleRoleSelectionDialogState
    extends ConsumerState<GoogleRoleSelectionDialog> {
  Role? _selectedRole;

  IconData _getIconForRole(String libelle) {
    final lower = libelle.toLowerCase();
    if (lower.contains('visiteur') || lower.contains('touriste')) {
      return Icons.luggage_outlined;
    } else if (lower.contains('hôte') || lower.contains('hote')) {
      return Icons.home_work_outlined;
    } else if (lower.contains('presta') || lower.contains('service')) {
      return Icons.design_services_outlined;
    } else if (lower.contains('guide')) {
      return Icons.explore_outlined;
    }
    return Icons.person_outline;
  }

  String _getDescriptionForRole(String libelle) {
    final lower = libelle.toLowerCase();
    if (lower.contains('visiteur') || lower.contains('touriste')) {
      return 'Explorez les événements, réservez des logements et vivez des expériences uniques.';
    } else if (lower.contains('hôte') || lower.contains('hote')) {
      return 'Proposez vos hébergements et logements aux voyageurs et visiteurs.';
    } else if (lower.contains('presta') || lower.contains('service')) {
      return 'Proposez vos services culturels, d\'organisation ou de transport.';
    } else if (lower.contains('guide')) {
      return 'Accompagnez et guidez les touristes lors de leurs visites culturelles.';
    }
    return 'Rejoignez la communauté Vodoo Host.';
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header avec icône Google et message d'accueil
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName.isNotEmpty
                            ? 'Bienvenue ${widget.userName} !'
                            : 'Bienvenue sur Vodoo Host !',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choisissez votre rôle pour continuer :',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Contenu des rôles
            rolesAsync.when(
              data: (roles) {
                final availableRoles = roles
                    .where((r) => !r.libelle.toLowerCase().contains('admin'))
                    .toList();

                if (availableRoles.isEmpty) {
                  return const Text('Aucun rôle disponible.');
                }

                return Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: availableRoles.map((role) {
                        final isSelected = _selectedRole?.id == role.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedRole = role;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.06)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getIconForRole(role.libelle),
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            role.libelle,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getDescriptionForRole(role.libelle),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Erreur de chargement des rôles',
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton d'action
            ElevatedButton(
              onPressed: _selectedRole == null
                  ? null
                  : () {
                      Navigator.of(context).pop(_selectedRole);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _selectedRole == null ? 0 : 2,
              ),
              child: const Text(
                'Confirmer mon rôle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
