import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/rituals/domain/models/ritual.dart';
import 'package:vodou/features/rituals/presentation/providers/ritual_provider.dart';

/// Section des rituels vaudou pour la page de détails du logement
class RitualsSection extends ConsumerWidget {
  final List<Ritual> rituals;

  const RitualsSection({super.key, required this.rituals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rituals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Expériences culturelles',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (rituals.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Afficher tous les rituels
                },
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Découvrez les rituels vaudou proposés par cet hôte',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        ...rituals.take(3).map((ritual) {
          return _buildRitualCard(context, ref, ritual);
        }),
      ],
    );
  }

  Widget _buildRitualCard(BuildContext context, WidgetRef ref, Ritual ritual) {
    final isSelected = ref.watch(
      selectedRitualsProvider.select((list) => list.contains(ritual.id)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          ref.read(selectedRitualsProvider.notifier).toggleRitual(ritual.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Symbole uniquement (pas de photo dans le schéma)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildSymboleIcon(ritual.symbole),
                  ),
                  const SizedBox(width: 16),
                  // Informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ritual.titre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Checkbox de sélection (empêche la propagation du clic)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                ref
                                    .read(selectedRitualsProvider.notifier)
                                    .toggleRitual(ritual.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.grey,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (ritual.diviniteNom != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ritual.diviniteNom!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          ritual.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (ritual.duree != null) ...[
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ritual.dureeFormatee,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (ritual.prix != null) ...[
                              const Icon(
                                Icons.payments_outlined,
                                size: 14,
                                color: AppColors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ritual.prixFormate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (!ritual.disponible)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Indisponible',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Détails du rituel (affichés si sélectionné)
            if (isSelected) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Durée
                    if (ritual.duree != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Durée: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ritual.dureeFormatee,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Description complète
                    const Text(
                      'Description complète',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ritual.description,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),

                    // Signification (si disponible)
                    if (ritual.signification != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Signification spirituelle',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          ritual.signification!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],

                    // Déroulement (si disponible)
                    if (ritual.deroulement != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Déroulement du rituel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ritual.deroulement!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],

                    // Précautions
                    if (ritual.precautions != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Précautions à prendre',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ritual.precautions!,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Prix (si disponible)
                    if (ritual.prix != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Prix: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ritual.prixFormate,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymboleIcon(String? symbole) {
    return Center(
      child: Text(symbole ?? '🕯️', style: const TextStyle(fontSize: 40)),
    );
  }
}
