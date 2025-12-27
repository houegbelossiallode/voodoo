import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/favorites/data/repositories/favorite_repository.dart';
import 'package:vodou/features/favorites/domain/models/favorite.dart';
import 'package:vodou/features/home/domain/models/logement.dart';

/// Provider pour le service Supabase
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

/// Provider pour le repository des favoris
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return FavoriteRepository(supabaseService);
});

/// Provider pour récupérer toutes les listes de favoris de l'utilisateur
final favoriteListsProvider = FutureProvider<List<Favorite>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return [];

  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.getUserFavoriteLists(user.id);
});

/// Provider pour récupérer tous les logements favoris (toutes listes confondues)
final favoriteLogementsProvider = FutureProvider<List<Logement>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return [];

  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.getAllUserFavoriteLogements(user.id);
});

/// Provider pour récupérer les logements d'une liste spécifique
final favoriteListLogementsProvider =
    FutureProvider.family<List<Logement>, int>((ref, favoriteId) async {
      final repository = ref.watch(favoriteRepositoryProvider);
      return repository.getLogementsFromFavoriteList(favoriteId);
    });

/// Provider pour vérifier si un logement est dans au moins une liste de favoris
final isLogementFavoriteProvider = FutureProvider.family<bool, int>((
  ref,
  logementId,
) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return false;

  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.isLogementInAnyFavorite(user.id, logementId);
});

/// StateNotifier pour gérer l'état des favoris (IDs des logements en favoris)
class FavoriteNotifier extends StateNotifier<Set<int>> {
  final FavoriteRepository _repository;
  final int? userId; // Peut être null si pas d'utilisateur connecté

  FavoriteNotifier(this._repository, this.userId) : super({}) {
    if (userId != null) {
      _loadFavorites();
    }
  }

  /// Charge les IDs des logements favoris
  Future<void> _loadFavorites() async {
    if (userId == null) return;

    try {
      final logements = await _repository.getAllUserFavoriteLogements(userId!);
      if (mounted) {
        state = logements.map((l) => l.id).toSet();
      }
    } catch (e) {
      // En cas d'erreur, on garde l'état vide
      if (mounted) {
        state = {};
      }
    }
  }

  /// Vérifie si un logement est en favoris (depuis le state)
  bool isFavorite(int logementId) {
    return state.contains(logementId);
  }

  /// Ajoute un logement aux favoris (met à jour le state)
  void addToState(int logementId) {
    state = {...state, logementId};
  }

  /// Retire un logement des favoris (met à jour le state)
  void removeFromState(int logementId) {
    state = state.where((id) => id != logementId).toSet();
  }

  /// Rafraîchit la liste des favoris
  Future<void> refresh() async {
    await _loadFavorites();
  }
}

/// Provider pour le notifier des favoris
final favoriteNotifierProvider =
    StateNotifierProvider<FavoriteNotifier, Set<int>>((ref) {
      final repository = ref.read(favoriteRepositoryProvider);
      // Utiliser watch au lieu de read pour réagir aux changements d'utilisateur
      final userAsync = ref.watch(currentUserProvider);
      final user = userAsync.value;

      // Passer null si pas d'utilisateur
      return FavoriteNotifier(repository, user?.id);
    });

/// Provider pour le nombre total de logements favoris
final favoritesCountProvider = Provider<int>((ref) {
  final favorites = ref.watch(favoriteNotifierProvider);
  return favorites.length;
});

/// Provider pour le nombre de listes de favoris
final favoriteListsCountProvider = Provider<int>((ref) {
  final listsAsync = ref.watch(favoriteListsProvider);
  return listsAsync.when(
    data: (lists) => lists.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
