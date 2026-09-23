import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/data/repositories/divinite_repository.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Page du questionnaire interactif pour les préférences culturelles
class QuestionnairePage extends ConsumerStatefulWidget {
  final bool isFirstTime; // true si c'est la première connexion

  const QuestionnairePage({super.key, this.isFirstTime = false});

  @override
  ConsumerState<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends ConsumerState<QuestionnairePage> {
  int _currentStep = 0;
  final List<int> _selectedDivinites = [];
  bool _assisterRituel = false;
  List<Divinite> _divinites = [];
  bool _isLoadingDivinites = true;

  // Icônes et couleurs par défaut pour les divinités
  final Map<String, Map<String, dynamic>> _diviniteStyles = {
    'Sakpata': {'icon': Icons.healing, 'color': Colors.brown},
    'Mamiwata': {'icon': Icons.water, 'color': Colors.blue},
    'Legba': {'icon': Icons.door_front_door, 'color': Colors.orange},
    'Hevioso': {'icon': Icons.flash_on, 'color': Colors.red},
    'Gu': {'icon': Icons.hardware, 'color': Colors.grey},
    'Dan': {'icon': Icons.waves, 'color': Colors.teal},
  };

  @override
  void initState() {
    super.initState();
    _loadDivinites();
    _loadExistingPreferences();
  }

  Future<void> _loadDivinites() async {
    try {
      final repository = DiviniteRepository(SupabaseService.instance);
      final divinites = await repository.getAllDivinites();
      setState(() {
        _divinites = divinites;
        _isLoadingDivinites = false;
      });
    } catch (e) {
      AppLogger.w('⚠️ Erreur chargement divinités: $e');
      setState(() {
        _isLoadingDivinites = false;
      });
    }
  }

  Future<void> _loadExistingPreferences() async {
    // Charger les préférences existantes si on est en mode modification
    if (!widget.isFirstTime) {
      try {
        AppLogger.d('🔍 Chargement des préférences existantes...');
        final preferencesAsync = await ref.read(
          currentUserPreferencesProvider.future,
        );

        if (preferencesAsync != null) {
          AppLogger.d('✅ Préférences trouvées:');
          AppLogger.d('   - Divinités: ${preferencesAsync.divinitesPreferees}');
          AppLogger.d(
            '   - Assister rituel: ${preferencesAsync.assisterRituel}',
          );

          setState(() {
            _selectedDivinites.clear();
            _selectedDivinites.addAll(preferencesAsync.divinitesPreferees);
            _assisterRituel = preferencesAsync.assisterRituel;
          });
        } else {
          AppLogger.w('⚠️ Aucune préférence existante trouvée');
        }
      } catch (e) {
        AppLogger.w('⚠️ Erreur chargement préférences: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: widget.isFirstTime
            ? 'Personnalisez votre expérience'
            : 'Mes préférences',
        leading: !widget.isFirstTime
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.go(AppRouter.home);
                },
              )
            : null,
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
    if (_isLoadingDivinites) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des divinités...'),
          ],
        ),
      );
    }

    if (_divinites.isEmpty) {
      return const Center(child: Text('Aucune divinité disponible'));
    }

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
            childAspectRatio: 0.72,
          ),
          itemCount: _divinites.length,
          itemBuilder: (context, index) {
            final divinite = _divinites[index];
            final isSelected = _selectedDivinites.contains(divinite.id);

            return _buildDiviniteCard(divinite, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildDiviniteCard(Divinite divinite, bool isSelected) {
    // Récupérer le style pour cette divinité (icône et couleur)
    final style =
        _diviniteStyles[divinite.nom] ??
        {'icon': Icons.star, 'color': Colors.purple};
    final icon = style['icon'] as IconData;
    final color = style['color'] as Color;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDivinites.remove(divinite.id);
          } else {
            _selectedDivinites.add(divinite.id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                divinite.nom,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  divinite.description ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
            ],
          ),
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
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
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
                    ? AppColors.primary.withValues(alpha: 0.2)
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
            color: Colors.black.withValues(alpha: 0.05),
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
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );

    try {
      AppLogger.d('💾 Début de la sauvegarde des préférences...');
      AppLogger.d('   Divinités: $_selectedDivinites');
      AppLogger.d('   Assister rituel: $_assisterRituel');

      final notifier = ref.read(userPreferencesNotifierProvider.notifier);

      await notifier.savePreferences(
        divinitesPreferees: _selectedDivinites,
        assisterRituel: _assisterRituel,
      );

      AppLogger.d('✅ Préférences sauvegardées avec succès');

      // Invalider les providers pour rafraîchir les données
      AppLogger.d('🔄 Rafraîchissement des providers...');
      ref.invalidate(currentUserPreferencesProvider);
      ref.invalidate(userPreferencesNotifierProvider);

      if (mounted) {
        // Fermer l'indicateur de chargement
        Navigator.of(context).pop();

        // Afficher le message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Préférences enregistrées avec succès !'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Utiliser addPostFrameCallback pour garantir que la navigation se fait après le rendu
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (widget.isFirstTime) {
              // Rediriger vers la page d'accueil
              AppLogger.d('🏠 Redirection vers home (première fois)');
              context.go(AppRouter.home);
            } else {
              // Retourner à l'onglet Profil (sur MainPageWrapper)
              AppLogger.d('🔙 Retour au profil');
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRouter.home, extra: 3); // Index 3 = Profil
              }
            }
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e('❌ Erreur lors de la sauvegarde: $e');
      AppLogger.d('📋 Stack trace: $stackTrace');

      if (mounted) {
        // Fermer l'indicateur de chargement
        Navigator.of(context).pop();

        // Afficher le message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
