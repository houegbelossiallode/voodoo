import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/app_image.dart';
import 'package:vodou/features/accommodation/domain/models/avis.dart';
import 'package:vodou/features/accommodation/presentation/providers/accommodation_details_provider.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';

/// Section des avis et évaluations
class AvisSection extends ConsumerStatefulWidget {
  final List<Avis> avisList;
  final AvisStats stats;
  final int logementId;

  const AvisSection({
    super.key,
    required this.avisList,
    required this.stats,
    required this.logementId,
  });

  @override
  ConsumerState<AvisSection> createState() => _AvisSectionState();
}

class _AvisSectionState extends ConsumerState<AvisSection> {
  bool _showAllReviews = false;

  @override
  Widget build(BuildContext context) {
    final displayedReviews = _showAllReviews
        ? widget.avisList
        : widget.avisList.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec statistiques
        Row(
          children: [
            Text(
              'Avis et évaluations',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.star, color: AppColors.rating, size: 20),
            const SizedBox(width: 4),
            Text(
              '${widget.stats.moyenneNote.toStringAsFixed(1)} (${widget.stats.totalAvis})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bouton pour laisser un avis
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _showReviewDialog(context),
            icon: const Icon(Icons.rate_review),
            label: const Text('Laisser un avis'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Répartition des notes
        if (widget.stats.totalAvis > 0) ...[
          _buildRatingDistribution(context),
          const SizedBox(height: 24),
        ],

        // Liste des avis
        if (widget.avisList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aucun avis pour le moment',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...displayedReviews.map((avis) {
            return _buildAvisCard(context, avis);
          }),

        // Bouton "Voir tous les avis" / "Voir moins"
        if (widget.avisList.length > 3)
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllReviews = !_showAllReviews;
                });
              },
              child: Text(
                _showAllReviews
                    ? 'Voir moins'
                    : 'Voir les ${widget.avisList.length} avis',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingDistribution(BuildContext context) {
    return Column(
      children: [
        for (int i = 5; i >= 1; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('$i'),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 16, color: AppColors.rating),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: widget.stats.totalAvis > 0
                        ? (widget.stats.repartitionNotes[i] ?? 0) /
                              widget.stats.totalAvis
                        : 0,
                    backgroundColor: AppColors.greyLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.rating,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${widget.stats.repartitionNotes[i] ?? 0}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAvisCard(BuildContext context, Avis avis) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de l'avis
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avis.userPhoto != null
                      ? AppImage.provider(avis.userPhoto!)
                      : null,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: avis.userPhoto == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avis.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(avis.dateCreation),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Note
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rating.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.rating),
                      const SizedBox(width: 4),
                      Text(
                        avis.note.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Commentaire
            if (avis.commentaire != null) ...[
              const SizedBox(height: 12),
              Text(avis.commentaire!, style: const TextStyle(fontSize: 14)),
            ],

            // Réponse de l'hôte
            if (avis.reponseHote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Réponse de l\'hôte',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      avis.reponseHote!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showReviewDialog(BuildContext context) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Laisser un avis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Votre note',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              setDialogState(() {
                                selectedRating = index + 1;
                              });
                            },
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: AppColors.rating,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Votre commentaire',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 5,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    hintText: 'Partagez votre expérience...',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (isSubmitting) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final user = ref.read(currentUserProvider).value;
                      if (user == null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vous devez être connecté pour laisser un avis',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final comment = commentController.text.trim();
                      if (comment.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez ajouter un commentaire'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        final repository = ref.read(
                          accommodationDetailsRepositoryProvider,
                        );
                        await repository.submitAvis(
                          logementId: widget.logementId,
                          userId: user.id,
                          note: selectedRating,
                          commentaire: comment,
                        );

                        // Rafraîchir les avis et les stats
                        ref.invalidate(logementAvisProvider(widget.logementId));
                        ref.invalidate(avisStatsProvider(widget.logementId));

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avis publié avec succès !'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                        });
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}
