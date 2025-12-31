import 'package:flutter/material.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/features/festivals/domain/models/festival.dart';

/// Page générique pour afficher un festival
class FestivalPage extends StatelessWidget {
  final Festival festival;

  const FestivalPage({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '${festival.ville}, ${festival.pays}'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du festival
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        festival.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(
                              Icons.festival,
                              size: 100,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Nom du festival
                Text(
                  festival.nom,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Localisation
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 24,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${festival.ville}, ${festival.pays}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Description
                Text(
                  festival.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Message "Bientôt disponible"
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 48,
                          color: AppColors.primary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Bientôt disponible',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Les hébergements pour ce festival seront disponibles prochainement',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
