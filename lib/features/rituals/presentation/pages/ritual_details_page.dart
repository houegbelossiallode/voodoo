import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/rituals/presentation/providers/ritual_provider.dart';
import 'package:vodou/features/rituals/domain/models/ritual.dart';

/// Page de détails d'un rituel vaudou
class RitualDetailsPage extends ConsumerWidget {
  final int ritualId;

  const RitualDetailsPage({super.key, required this.ritualId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ritualAsync = ref.watch(ritualDetailsProvider(ritualId));

    return ritualAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: const CustomAppBar(title: 'Erreur'),
        body: Center(child: Text('Erreur: $error')),
      ),
      data: (ritual) {
        if (ritual == null) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Rituel introuvable'),
            body: const Center(child: Text('Ce rituel n\'existe pas')),
          );
        }

        return _buildContent(context, ref, ritual);
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Ritual ritual) {
    final isSelected = ref.watch(
      selectedRitualsProvider.select((list) => list.contains(ritual.id)),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ritualDetailsProvider(ritualId));
        },
        child: CustomScrollView(
        slivers: [
          // Symbole d'en-tête (pas de photo dans le schéma)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildPlaceholder(ritual.symbole),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Partager
                },
              ),
            ],
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et badge disponibilité
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ritual.titre,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!ritual.disponible)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Indisponible',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Divinité associée
                  if (ritual.diviniteNom != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ritual.diviniteNom!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Informations rapides
                  Row(
                    children: [
                      if (ritual.duree != null) ...[
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ritual.dureeFormatee,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 24),
                      ],
                      if (ritual.prix != null) ...[
                        const Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ritual.prixFormate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const Divider(height: 32),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ritual.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),

                  // Signification
                  if (ritual.signification != null) ...[
                    const Divider(height: 32),
                    Text(
                      'Signification spirituelle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        ritual.signification!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],

                  // Déroulement
                  if (ritual.deroulement != null) ...[
                    const Divider(height: 32),
                    Text(
                      'Déroulement du rituel',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ritual.deroulement!,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],

                  // Précautions
                  if (ritual.precautions != null) ...[
                    const Divider(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Précautions à prendre',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ritual.precautions!,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: ritual.disponible
                ? () {
                    ref
                        .read(selectedRitualsProvider.notifier)
                        .toggleRitual(ritual.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSelected
                              ? 'Rituel retiré de la sélection'
                              : 'Rituel ajouté à la sélection',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected
                  ? AppColors.success
                  : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSelected ? '✓ Sélectionné' : 'Sélectionner ce rituel',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String? symbole) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(symbole ?? '🕯️', style: const TextStyle(fontSize: 100)),
      ),
    );
  }
}
