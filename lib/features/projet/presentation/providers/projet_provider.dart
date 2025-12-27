import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/projet/data/repositories/projet_repository.dart';
import 'package:vodou/features/projet/domain/models/projet.dart';

/// Provider pour le repository de projet
final projetRepositoryProvider = Provider<ProjetRepository>((ref) {
  return ProjetRepository(SupabaseService.instance);
});

/// Provider pour tous les projets actifs
final allProjetsProvider = FutureProvider<List<Projet>>((ref) async {
  final repository = ref.read(projetRepositoryProvider);
  return repository.getAllProjets();
});

/// Provider pour un projet spécifique
final projetByIdProvider = FutureProvider.family<Projet?, int>((
  ref,
  projetId,
) async {
  final repository = ref.read(projetRepositoryProvider);
  return repository.getProjetById(projetId);
});

/// Provider pour les projets par catégorie
final projetsByCategorieProvider = FutureProvider.family<List<Projet>, int>((
  ref,
  categorieId,
) async {
  final repository = ref.read(projetRepositoryProvider);
  return repository.getProjetsByCategorie(categorieId);
});

/// Provider pour les contributions d'un projet
final projetContributionsProvider =
    FutureProvider.family<List<Contribution>, int>((ref, projetId) async {
      final repository = ref.read(projetRepositoryProvider);
      return repository.getProjetContributions(projetId);
    });

/// Provider pour les statistiques d'un projet
final projetStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, projetId) async {
      final repository = ref.read(projetRepositoryProvider);
      return repository.getProjetStatistics(projetId);
    });

/// Provider pour toutes les catégories
final allCategoriesProvider = FutureProvider<List<Categorie>>((ref) async {
  final repository = ref.read(projetRepositoryProvider);
  return repository.getAllCategories();
});

/// State Notifier pour gérer la sélection de projet
class ProjetSelectionNotifier extends StateNotifier<Projet?> {
  ProjetSelectionNotifier() : super(null);

  void selectProjet(Projet? projet) {
    state = projet;
  }

  void clearSelection() {
    state = null;
  }
}

/// Provider pour la sélection de projet
final projetSelectionProvider =
    StateNotifierProvider<ProjetSelectionNotifier, Projet?>((ref) {
      return ProjetSelectionNotifier();
    });
