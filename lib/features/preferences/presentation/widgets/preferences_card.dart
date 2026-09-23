import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';

/// Widget card pour afficher et modifier les préférences culturelles
/// À intégrer dans la page de profil
class PreferencesCard extends ConsumerWidget {
  const PreferencesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(currentUserPreferencesProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Expérience culturelle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
                    context.push(AppRouter.questionnaire);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            preferencesAsync.when(
              data: (preferences) {
                if (preferences == null || !preferences.hasPreferences) {
                  return _buildEmptyState(context);
                }
                return _buildPreferencesContent(preferences);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.help_outline, size: 48, color: AppColors.greyLight),
        const SizedBox(height: 12),
        const Text(
          'Aucune préférence définie',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.push(AppRouter.questionnaire, extra: true);
          },
          icon: const Icon(Icons.add),
          label: const Text('Définir mes préférences'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesContent(preferences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divinités préférées
        if (preferences.divinitesPreferees.isNotEmpty) ...[
          const Text(
            'Divinités d\'intérêt',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preferences.divinitesPreferees.map<Widget>((divinite) {
              return Chip(
                label: Text(
                  _getDiviniteName(divinite),
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: const BorderSide(color: AppColors.primary),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Assister à un rituel
        Row(
          children: [
            Icon(
              preferences.assisterRituel ? Icons.check_circle : Icons.cancel,
              color: preferences.assisterRituel
                  ? AppColors.success
                  : AppColors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              preferences.assisterRituel
                  ? 'Intéressé par les rituels'
                  : 'Pas intéressé par les rituels',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 12),
        const Text(
          'Erreur lors du chargement',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _getDiviniteName(String id) {
    final names = {
      'sakpata': 'Sakpata',
      'mamiwata': 'Mamiwata',
      'legba': 'Legba',
      'hevioso': 'Hevioso',
      'gu': 'Gu',
      'dan': 'Dan',
    };
    return names[id] ?? id;
  }
}
