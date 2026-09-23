import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/search/data/repositories/search_repository.dart';
import 'package:vodou/features/search/domain/models/search_filters.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Provider pour le repository de recherche
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final supabaseService = SupabaseService.instance;
  return SearchRepository(supabaseService);
});

/// StateNotifier pour gérer les filtres de recherche
class SearchFiltersNotifier extends StateNotifier<SearchFilters> {
  SearchFiltersNotifier() : super(const SearchFilters());

  /// Met à jour la destination
  void setDestination(String? destination) {
    state = state.copyWith(destination: destination);
  }

  /// Met à jour les dates
  void setDates(DateTime? dateDebut, DateTime? dateFin) {
    state = state.copyWith(dateDebut: dateDebut, dateFin: dateFin);
  }

  /// Met à jour le nombre de voyageurs
  void setNbVoyageurs(int? nbVoyageurs) {
    state = state.copyWith(nbVoyageurs: nbVoyageurs);
  }

  /// Met à jour la fourchette de prix
  void setPrixRange(double? min, double? max) {
    state = state.copyWith(prixMin: min, prixMax: max);
  }

  /// Met à jour les divinités
  void setDivinites(List<int> divinites) {
    state = state.copyWith(divinites: divinites);
  }

  /// Ajoute une divinité
  void addDivinite(int divinite) {
    final newList = [...state.divinites, divinite];
    state = state.copyWith(divinites: newList);
  }

  /// Retire une divinité
  void removeDivinite(int divinite) {
    final newList = state.divinites.where((d) => d != divinite).toList();
    state = state.copyWith(divinites: newList);
  }

  /// Met à jour les équipements
  void setEquipements(List<int> equipements) {
    state = state.copyWith(equipements: equipements);
  }

  /// Ajoute un équipement
  void addEquipement(int equipementId) {
    final newList = [...state.equipements, equipementId];
    state = state.copyWith(equipements: newList);
  }

  /// Retire un équipement
  void removeEquipement(int equipementId) {
    final newList = state.equipements.where((e) => e != equipementId).toList();
    state = state.copyWith(equipements: newList);
  }

  /// Met à jour les langues de l'hôte
  void setLanguesHote(List<String> langues) {
    state = state.copyWith(languesHote: langues);
  }

  /// Met à jour le nombre minimum de chambres
  void setNbChambresMin(int? nbChambres) {
    state = state.copyWith(nbChambresMin: nbChambres);
  }

  /// Met à jour le quartier
  void setQuartierId(int? quartierId) {
    state = state.copyWith(quartierId: quartierId);
  }

  /// Met à jour le filtre rituel
  void setAssisterRituel(bool? assisterRituel) {
    state = state.copyWith(assisterRituel: assisterRituel);
  }

  /// Réinitialise tous les filtres
  void clearFilters() {
    state = const SearchFilters();
  }

  /// Applique les filtres depuis les préférences utilisateur
  void applyFromPreferences({
    required List<int> divinites,
    required bool assisterRituel,
  }) {
    state = state.copyWith(
      divinites: divinites,
      assisterRituel: assisterRituel,
    );
  }
}

/// Provider pour les filtres de recherche
final searchFiltersProvider =
    StateNotifierProvider<SearchFiltersNotifier, SearchFilters>((ref) {
      return SearchFiltersNotifier();
    });

/// Provider pour les résultats de recherche
final searchResultsProvider = FutureProvider<List<Logement>>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  final repository = ref.watch(searchRepositoryProvider);

  // Ne rechercher que si au moins un filtre est appliqué
  if (!filters.hasFilters) {
    return [];
  }

  AppLogger.d('🔍 Recherche avec ${filters.activeFiltersCount} filtre(s)');
  return repository.searchLogements(filters);
});

/// Provider pour les suggestions de destination
final destinationSuggestionsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, query) async {
      if (query.isEmpty) return [];

      final repository = ref.watch(searchRepositoryProvider);
      return repository.getDestinationSuggestions(query);
    });

/// Provider pour la liste des quartiers
final quartiersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(searchRepositoryProvider);
  return repository.getQuartiers();
});
