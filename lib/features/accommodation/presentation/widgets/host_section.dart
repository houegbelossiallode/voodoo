import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/app_image.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/accommodation/domain/models/host_info.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Section des informations sur l'hôte
class HostSection extends ConsumerWidget {
  final HostInfo host;
  final int? logementId;

  const HostSection({super.key, required this.host, this.logementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec photo et nom
            Row(
              children: [
                // Photo de profil
                CircleAvatar(
                  radius: 35,
                  backgroundImage: host.photo != null
                      ? AppImage.provider(host.photo!)
                      : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: host.photo == null
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Hôte: ${host.fullName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (host.superHost) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Super Hôte',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (host.dateInscription != null)
                        Text(
                          'Membre depuis ${_formatDate(host.dateInscription!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Statistiques
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (host.noteGlobale != null)
                  _buildStat(
                    icon: Icons.star,
                    label: '${host.noteGlobale!.toStringAsFixed(1)} étoiles',
                  ),
                if (host.nombreAvis != null)
                  _buildStat(
                    icon: Icons.rate_review,
                    label: '${host.nombreAvis} avis',
                  ),
                if (host.nombreLogements != null)
                  _buildStat(
                    icon: Icons.home,
                    label:
                        '${host.nombreLogements} logement${host.nombreLogements! > 1 ? 's' : ''}',
                  ),
              ],
            ),

            // Bio
            if (host.bio != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(host.bio!, style: const TextStyle(fontSize: 14)),
            ],

            // Langues
            if (host.langues.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.language,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Langues parlées: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      host.langues.join(', '),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],

            // Passions
            if (host.passions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Passions: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: host.passions.map((passion) {
                        return Chip(
                          label: Text(passion),
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Bouton contacter
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _contactHost(context, ref),
                icon: const Icon(Icons.message),
                label: const Text('Contacter l\'hôte'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _contactHost(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour contacter l\'hôte'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Créer ou récupérer la conversation
      final conversation = await ref
          .read(conversationCreatorProvider.notifier)
          .getOrCreateConversation(
            visiteurId: user.id,
            hoteId: host.id,
            logementId: logementId,
          );

      // Fermer le loader
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (conversation != null && context.mounted) {
        // Naviguer vers la page de chat
        context.push(
          AppRouter.chat.replaceAll(
            ':conversationId',
            conversation.id.toString(),
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création de la conversation'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Fermer le loader
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.toMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
