import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/data/repositories/divinite_repository.dart';
import 'package:vodou/features/home/data/repositories/logement_repository.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/preferences/presentation/providers/preferences_provider.dart';

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

/// Provider pour récupérer uniquement les divinités préférées de l'utilisateur
final preferredDivinitesProvider = FutureProvider<List<Divinite>>((ref) async {
  print('🎯 Chargement des divinités préférées...');

  // Récupérer les préférences de l'utilisateur
  final preferencesAsync = await ref.watch(
    currentUserPreferencesProvider.future,
  );
  final repository = ref.watch(diviniteRepositoryProvider);

  // Si pas de préférences, retourner toutes les divinités
  if (preferencesAsync == null || preferencesAsync.divinitesPreferees.isEmpty) {
    print('ℹ️ Pas de préférences → toutes les divinités');
    return repository.getAllDivinites();
  }

  print('✅ Préférences trouvées: ${preferencesAsync.divinitesPreferees}');

  // Récupérer toutes les divinités et filtrer par IDs préférés
  final allDivinites = await repository.getAllDivinites();
  final preferredDivinites = allDivinites
      .where(
        (divinite) => preferencesAsync.divinitesPreferees.contains(divinite.id),
      )
      .toList();

  print('📊 ${preferredDivinites.length} divinités préférées trouvées');
  return preferredDivinites;
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
