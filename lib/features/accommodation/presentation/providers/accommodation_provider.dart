import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/features/accommodation/data/repositories/accommodation_repository.dart';
import 'package:vodou/features/accommodation/domain/models/logement.dart';

/// Provider pour le repository des logements
final accommodationRepositoryProvider = Provider<AccommodationRepository>((
  ref,
) {
  return AccommodationRepository();
});

/// Provider pour la liste des logements
final accommodationsProvider = FutureProvider<List<Logement>>((ref) async {
  final repository = ref.read(accommodationRepositoryProvider);
  return await repository.getAccommodations();
});

/// Provider pour les logements recommandés
final recommendedAccommodationsProvider = FutureProvider<List<Logement>>((
  ref,
) async {
  final repository = ref.read(accommodationRepositoryProvider);
  return await repository.getRecommendedAccommodations();
});

/// Provider pour un logement spécifique
final accommodationByIdProvider = FutureProvider.autoDispose
    .family<Logement?, String>((ref, id) async {
      final repository = ref.read(accommodationRepositoryProvider);
      return await repository.getAccommodationById(id);
    });

/// Provider pour la recherche de logements
final accommodationSearchProvider =
    StateNotifierProvider<
      AccommodationSearchNotifier,
      AccommodationSearchState
    >((ref) {
      return AccommodationSearchNotifier(
        ref.read(accommodationRepositoryProvider),
      );
    });

/// État de la recherche
class AccommodationSearchState {
  final List<Logement> results;
  final bool isLoading;
  final String? error;
  final SearchFilters filters;

  AccommodationSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.filters = const SearchFilters(),
  });

  AccommodationSearchState copyWith({
    List<Logement>? results,
    bool? isLoading,
    String? error,
    SearchFilters? filters,
  }) {
    return AccommodationSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filters: filters ?? this.filters,
    );
  }
}

/// Filtres de recherche
class SearchFilters {
  final String? destination;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guests;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? deities;
  final List<String>? amenities;

  const SearchFilters({
    this.destination,
    this.checkIn,
    this.checkOut,
    this.guests,
    this.minPrice,
    this.maxPrice,
    this.deities,
    this.amenities,
  });

  SearchFilters copyWith({
    String? destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    double? minPrice,
    double? maxPrice,
    List<String>? deities,
    List<String>? amenities,
  }) {
    return SearchFilters(
      destination: destination ?? this.destination,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      deities: deities ?? this.deities,
      amenities: amenities ?? this.amenities,
    );
  }
}

/// Notifier pour gérer la recherche
class AccommodationSearchNotifier
    extends StateNotifier<AccommodationSearchState> {
  final AccommodationRepository _repository;

  AccommodationSearchNotifier(this._repository)
    : super(AccommodationSearchState());

  /// Met à jour les filtres
  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters);
  }

  /// Effectue une recherche
  Future<void> search() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _repository.searchAccommodations(
        destination: state.filters.destination,
        checkIn: state.filters.checkIn,
        checkOut: state.filters.checkOut,
        guests: state.filters.guests,
        minPrice: state.filters.minPrice,
        maxPrice: state.filters.maxPrice,
        deities: state.filters.deities,
        amenities: state.filters.amenities,
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Réinitialise la recherche
  void reset() {
    state = AccommodationSearchState();
  }
}
