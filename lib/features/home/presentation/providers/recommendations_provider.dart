import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/data/repositories/logement_repository.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';

/// Provider pour le repository des logements
final logementRepositoryProvider = Provider<LogementRepository>((ref) {
  final supabaseService = SupabaseService.instance;
  return LogementRepository(supabaseService);
});

/// Provider pour les logements recommandés basés sur les préférences utilisateur
/// Filtre automatiquement par divinités préférées et disponibilité
final recommendedLogementsProvider = FutureProvider<List<Logement>>((
  ref,
) async {
  print('🎯 Chargement des recommandations personnalisées...');

  // Récupérer les préférences de l'utilisateur
  final preferencesAsync = await ref.watch(
    currentUserPreferencesProvider.future,
  );
  final repository = ref.watch(logementRepositoryProvider);

  // Si pas de préférences ou pas de divinités sélectionnées
  if (preferencesAsync == null || preferencesAsync.divinitesPreferees.isEmpty) {
    print('ℹ️ Pas de préférences → logements généraux');
    return repository.getRecommendedLogements(limit: 10);
  }

  print('✅ Préférences trouvées: ${preferencesAsync.divinitesPreferees}');

  // Récupérer les logements filtrés par divinités préférées
  final logements = await repository.getLogementsByDiviniteNames(
    preferencesAsync.divinitesPreferees,
    disponibleOnly: true, // Uniquement les logements disponibles
    limit: 20,
  );

  print('📊 ${logements.length} logements recommandés');
  return logements;
});

/// Provider pour tous les logements disponibles
final availableLogementsProvider = FutureProvider<List<Logement>>((ref) async {
  final repository = ref.watch(logementRepositoryProvider);
  return repository.getAllLogements(limit: 20);
});

/// Provider pour vérifier la disponibilité d'un logement
final logementDisponibiliteProvider =
    FutureProvider.family<bool, LogementDisponibiliteParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(logementRepositoryProvider);
      return repository.checkDisponibilite(
        params.logementId,
        params.dateDebut,
        params.dateFin,
      );
    });

/// Paramètres pour vérifier la disponibilité
class LogementDisponibiliteParams {
  final int logementId;
  final DateTime dateDebut;
  final DateTime dateFin;

  LogementDisponibiliteParams({
    required this.logementId,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogementDisponibiliteParams &&
          runtimeType == other.runtimeType &&
          logementId == other.logementId &&
          dateDebut == other.dateDebut &&
          dateFin == other.dateFin;

  @override
  int get hashCode =>
      logementId.hashCode ^ dateDebut.hashCode ^ dateFin.hashCode;
}
