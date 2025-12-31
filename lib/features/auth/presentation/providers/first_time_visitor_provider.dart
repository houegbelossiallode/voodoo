import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider pour gérer l'état des visiteurs qui doivent passer par le questionnaire
final needsQuestionnaireProvider = StateProvider<bool>((ref) => false);

/// Provider pour marquer qu'un visiteur vient de s'inscrire
final justSignedUpAsVisitorProvider = StateProvider<bool>((ref) => false);
