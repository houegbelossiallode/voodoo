import 'package:flutter/material.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/app_image.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';

/// Section des divinités
class DivinitesSection extends StatelessWidget {
  final List<Divinite> divinites;

  const DivinitesSection({super.key, required this.divinites});

  @override
  Widget build(BuildContext context) {
    if (divinites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Divinités et rituels',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Découvrez les divinités vénérées dans ce logement',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        ...divinites.map((divinite) {
          return _buildDiviniteCard(context, divinite);
        }),
      ],
    );
  }

  Widget _buildDiviniteCard(BuildContext context, Divinite divinite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDiviniteDetailsDialog(context, divinite),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image ou icône
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppImage(
                  url: divinite.image,
                  fit: BoxFit.cover,
                  errorWidget: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    divinite.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (divinite.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      divinite.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    ),
  );
}

  void _showDiviniteDetailsDialog(BuildContext context, Divinite divinite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                divinite.nom,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (divinite.image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppImage(
                    url: divinite.image,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Description et histoire',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                divinite.description ?? 'Aucune description disponible pour cette divinité.',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
