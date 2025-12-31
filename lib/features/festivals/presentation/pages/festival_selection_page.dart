import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/festivals/domain/models/festival.dart';
import 'package:vodou/features/festivals/presentation/pages/festival_page.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';

class FestivalSelectionPage extends ConsumerWidget {
  final bool isFirstTime;

  const FestivalSelectionPage({super.key, this.isFirstTime = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final festivals = Festival.getFestivals();

    print('🎪 FestivalSelectionPage - isFirstTime (paramètre): $isFirstTime');

    return Scaffold(
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
              children: [
                const SizedBox(height: 40),
                // Titre
                Text(
                  isFirstTime ? 'Bienvenue !' : 'Choisissez votre festival',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isFirstTime
                      ? 'Sélectionnez le festival qui vous intéresse'
                      : 'Quel festival souhaitez-vous explorer ?',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                // Liste des festivals
                Expanded(
                  child: ListView.builder(
                    itemCount: festivals.length,
                    itemBuilder: (context, index) {
                      final festival = festivals[index];
                      return _buildFestivalCard(context, ref, festival);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFestivalCard(
    BuildContext context,
    WidgetRef ref,
    Festival festival,
  ) {
    return GestureDetector(
      onTap: () => _onFestivalSelected(context, ref, festival),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // Image en cercle
            Container(
              width: 200,
              height: 200,
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
                        size: 80,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nom du festival
            Text(
              festival.nom,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Ville et pays
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${festival.ville}, ${festival.pays}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              festival.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onFestivalSelected(
    BuildContext context,
    WidgetRef ref,
    Festival festival,
  ) async {
    print('🎉 Festival sélectionné: ${festival.nom}');
    print('   festival.id: ${festival.id}');

    // Vodun Days → Vodoo Host (page d'accueil)
    if (festival.id == 'vodun_days') {
      print('   ✅ Festival Vodun Days détecté');

      // Vérifier si l'utilisateur a des préférences
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.role?.toLowerCase() == 'visiteur') {
        try {
          print('   🔍 Vérification des préférences utilisateur...');
          final hasCompleted = await ref.read(
            hasCompletedQuestionnaireProvider.future,
          );

          print('   📊 hasCompleted = $hasCompleted');

          if (!hasCompleted) {
            // Pas de préférences → aller au questionnaire
            print(
              '   📋 Aucune préférence → Redirection vers le questionnaire',
            );
            if (context.mounted) {
              context.go(AppRouter.questionnaire, extra: true);
            }
          } else {
            // Préférences existantes → aller à la page d'accueil
            print('   🏠 Préférences existantes → Redirection vers Vodoo Host');
            if (context.mounted) {
              context.go(AppRouter.home);
            }
          }
        } catch (e) {
          print('   ⚠️ Erreur vérification préférences: $e');
          // En cas d'erreur, rediriger vers le questionnaire par sécurité
          if (context.mounted) {
            context.go(AppRouter.questionnaire, extra: true);
          }
        }
      } else {
        // Non visiteur → aller directement à la page d'accueil
        print('   🏠 Non visiteur → Redirection vers Vodoo Host');
        if (context.mounted) {
          context.go(AppRouter.home);
        }
      }
    } else {
      // Autres festivals → page générique du festival
      print(
        '   🎪 Autre festival → Redirection vers la page du festival ${festival.nom}',
      );
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FestivalPage(festival: festival),
          ),
        );
      }
    }
  }
}
