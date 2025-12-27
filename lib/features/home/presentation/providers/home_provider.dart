import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/data/repositories/divinite_repository.dart';
import 'package:vodou/features/home/data/repositories/logement_repository.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';
import 'package:vodou/features/home/domain/models/logement.dart';

/// Provider pour le service Supabase
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

/// Provider pour le repository des divinités
final diviniteRepositoryProvider = Provider<DiviniteRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return DiviniteRepository(supabaseService);
});

/// Provider pour le repository des logements
final logementRepositoryProvider = Provider<LogementRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return LogementRepository(supabaseService);
});

/// Provider pour récupérer toutes les divinités
final divinitesProvider = FutureProvider<List<Divinite>>((ref) async {
  final repository = ref.watch(diviniteRepositoryProvider);
  return repository.getAllDivinites();
});

/// Provider pour récupérer tous les logements
final logementsProvider = FutureProvider<List<Logement>>((ref) async {
  final repository = ref.watch(logementRepositoryProvider);
  return repository.getAllLogements(limit: 20);
});

/// Provider pour récupérer les logements recommandés
final recommendedLogementsProvider = FutureProvider<List<Logement>>((
  ref,
) async {
  final repository = ref.watch(logementRepositoryProvider);
  return repository.getRecommendedLogements(limit: 10);
});

/// Provider pour récupérer les logements par divinité
final logementsByDiviniteProvider = FutureProvider.family<List<Logement>, int>((
  ref,
  diviniteId,
) async {
  final repository = ref.watch(logementRepositoryProvider);
  return repository.getLogementsByDivinite(diviniteId);
});

/// Provider pour rechercher des logements par ville
final searchLogementsByVilleProvider =
    FutureProvider.family<List<Logement>, String>((ref, ville) async {
      final repository = ref.watch(logementRepositoryProvider);
      return repository.searchLogementsByVille(ville);
    });
