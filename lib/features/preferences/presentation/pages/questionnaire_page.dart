import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';

/// Page du questionnaire interactif pour les préférences culturelles
class QuestionnairePage extends ConsumerStatefulWidget {
  final bool isFirstTime; // true si c'est la première connexion

  const QuestionnairePage({super.key, this.isFirstTime = false});

  @override
  ConsumerState<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends ConsumerState<QuestionnairePage> {
  int _currentStep = 0;
  final List<String> _selectedDivinites = [];
  bool _assisterRituel = false;

  // Liste des divinités avec leurs icônes et descriptions
  final List<Map<String, dynamic>> _divinites = [
    {
      'id': 'sakpata',
      'nom': 'Sakpata',
      'icon': Icons.healing,
      'color': Colors.brown,
      'description': 'Divinité de la terre et de la guérison',
    },
    {
      'id': 'mamiwata',
      'nom': 'Mamiwata',
      'icon': Icons.water,
      'color': Colors.blue,
      'description': 'Déesse des eaux et de la richesse',
    },
    {
      'id': 'legba',
      'nom': 'Legba',
      'icon': Icons.door_front_door,
      'color': Colors.orange,
      'description': 'Gardien des portes et des chemins',
    },
    {
      'id': 'hevioso',
      'nom': 'Hevioso',
      'icon': Icons.flash_on,
      'color': Colors.red,
      'description': 'Dieu du tonnerre et de la foudre',
    },
    {
      'id': 'gu',
      'nom': 'Gu',
      'icon': Icons.hardware,
      'color': Colors.grey,
      'description': 'Dieu du fer et de la guerre',
    },
    {
      'id': 'dan',
      'nom': 'Dan',
      'icon': Icons.waves,
      'color': Colors.teal,
      'description': 'Serpent arc-en-ciel, symbole de richesse',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isFirstTime
              ? 'Personnalisez votre expérience'
              : 'Modifier mes préférences',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: widget.isFirstTime
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),

          // Contenu de l'étape actuelle
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStep(),
            ),
          ),

          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: AppColors.surface,
      child: Row(
        children: List.generate(2, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? AppColors.primary
                    : AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildDivinitesStep();
      case 1:
        return _buildRituelStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Étape 1 : Sélection des divinités
  Widget _buildDivinitesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, size: 64, color: AppColors.secondary),
        const SizedBox(height: 24),
        const Text(
          'Quelles divinités souhaitez-vous découvrir ?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sélectionnez une ou plusieurs divinités qui vous intéressent',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _divinites.length,
          itemBuilder: (context, index) {
            final divinite = _divinites[index];
            final isSelected = _selectedDivinites.contains(divinite['id']);

            return _buildDiviniteCard(divinite, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildDiviniteCard(Map<String, dynamic> divinite, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDivinites.remove(divinite['id']);
          } else {
            _selectedDivinites.add(divinite['id']);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? divinite['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? divinite['color'] : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: divinite['color'].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: divinite['color'].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(divinite['icon'], size: 40, color: divinite['color']),
            ),
            const SizedBox(height: 12),
            Text(
              divinite['nom'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? divinite['color'] : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                divinite['description'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Étape 2 : Assister à un rituel
  Widget _buildRituelStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.celebration, size: 64, color: AppColors.secondary),
        const SizedBox(height: 24),
        const Text(
          'Souhaitez-vous assister à un rituel en direct ?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vivez une expérience authentique et immersive',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        _buildRituelOption(
          title: 'Oui, je suis intéressé(e)',
          subtitle: 'Je souhaite participer à des rituels traditionnels',
          icon: Icons.check_circle_outline,
          value: true,
          selected: _assisterRituel == true,
        ),
        const SizedBox(height: 16),
        _buildRituelOption(
          title: 'Non, pas pour le moment',
          subtitle: 'Je préfère découvrir la culture autrement',
          icon: Icons.cancel_outlined,
          value: false,
          selected: _assisterRituel == false,
        ),
      ],
    );
  }

  Widget _buildRituelOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _assisterRituel = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.greyLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.grey,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canContinue = _canContinue();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Précédent'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canContinue ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppColors.greyLight,
              ),
              child: Text(
                _currentStep < 1 ? 'Continuer' : 'Terminer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedDivinites.isNotEmpty;
      case 1:
        return true; // Toujours vrai car on a une valeur par défaut
      default:
        return false;
    }
  }

  void _handleNext() async {
    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Sauvegarder les préférences
      await _savePreferences();
    }
  }

  Future<void> _savePreferences() async {
    try {
      final notifier = ref.read(userPreferencesNotifierProvider.notifier);

      await notifier.savePreferences(
        divinitesPreferees: _selectedDivinites,
        assisterRituel: _assisterRituel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences enregistrées avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );

        if (widget.isFirstTime) {
          // Rediriger vers la page d'accueil
          context.go(AppRouter.home);
        } else {
          // Fermer la page
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
