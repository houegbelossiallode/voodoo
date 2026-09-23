import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Widget qui vérifie si l'utilisateur a complété le questionnaire
/// et le redirige automatiquement si ce n'est pas le cas
class FirstTimeQuestionnaireChecker extends ConsumerStatefulWidget {
  final Widget child;

  const FirstTimeQuestionnaireChecker({super.key, required this.child});

  @override
  ConsumerState<FirstTimeQuestionnaireChecker> createState() =>
      _FirstTimeQuestionnaireCheckerState();
}

class _FirstTimeQuestionnaireCheckerState
    extends ConsumerState<FirstTimeQuestionnaireChecker> {
  bool _hasChecked = false;

  @override
  Widget build(BuildContext context) {
    final hasCompletedAsync = ref.watch(hasCompletedQuestionnaireProvider);

    return hasCompletedAsync.when(
      data: (hasCompleted) {
        // Vérifier une seule fois pour éviter les boucles
        if (!_hasChecked && !hasCompleted) {
          _hasChecked = true;
          // Rediriger vers le questionnaire après le build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go(AppRouter.questionnaire, extra: true);
            }
          });
        }

        return widget.child;
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) {
        // En cas d'erreur, afficher l'enfant quand même
        AppLogger.w('⚠️ Erreur vérification questionnaire: $error');
        return widget.child;
      },
    );
  }
}
