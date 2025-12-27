import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/favorites/domain/models/favorite.dart';
import 'package:vodou/features/home/domain/models/logement.dart';

/// Repository pour gérer les favoris
class FavoriteRepository {
  final SupabaseService _supabaseService;

  FavoriteRepository(this._supabaseService);

  /// Récupère toutes les listes de favoris d'un utilisateur
  Future<List<Favorite>> getUserFavoriteLists(int userId) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.favoritesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Favorite.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des listes de favoris: $e',
      );
    }
  }

  /// Crée une nouvelle liste de favoris
  Future<Favorite> createFavoriteList({
    required int userId,
    required String libelle,
    String? lienPartage,
  }) async {
    try {
      final newFavorite = await _supabaseService.client
          .from(SupabaseConfig.favoritesTable)
          .insert({
            'user_id': userId,
            'libelle': libelle.trim(),
            'lien_partage': lienPartage ?? '',
            'est_partage': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Favorite.fromJson(newFavorite);
    } catch (e) {
      throw Exception('Erreur lors de la création de la liste: $e');
    }
  }

  /// Récupère une liste de favoris par son ID
  Future<Favorite> getFavoriteListById(int favoriteId) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.favoritesTable)
          .select()
          .eq('id', favoriteId)
          .single();

      return Favorite.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la liste: $e');
    }
  }

  /// Vérifie si un logement est dans au moins une liste de favoris
  Future<bool> isLogementInAnyFavorite(int userId, int logementId) async {
    try {
      final lists = await getUserFavoriteLists(userId);
      if (lists.isEmpty) return false;

      final listIds = lists.map((l) => l.id).toList();

      final response = await _supabaseService.client
          .from(SupabaseConfig.favoriLogementsTable)
          .select()
          .inFilter('favorite_id', listIds)
          .eq('logement_id', logementId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Récupère les IDs des listes contenant un logement
  Future<List<int>> getFavoriteListsContainingLogement(
    int userId,
    int logementId,
  ) async {
    try {
      final lists = await getUserFavoriteLists(userId);
      if (lists.isEmpty) return [];

      final listIds = lists.map((l) => l.id).toList();

      final response = await _supabaseService.client
          .from(SupabaseConfig.favoriLogementsTable)
          .select('favorite_id')
          .inFilter('favorite_id', listIds)
          .eq('logement_id', logementId);

      return (response as List)
          .map((item) => item['favorite_id'] as int)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Ajoute un logement à une liste de favoris spécifique
  Future<void> addLogementToFavorite(int favoriteId, int logementId) async {
    try {
      // Vérifier si déjà dans cette liste
      final existing = await _supabaseService.client
          .from(SupabaseConfig.favoriLogementsTable)
          .select()
          .eq('favorite_id', favoriteId)
          .eq('logement_id', logementId)
          .maybeSingle();

      if (existing != null) {
        return; // Déjà dans cette liste
      }

      await _supabaseService.client
          .from(SupabaseConfig.favoriLogementsTable)
          .insert({
            'favorite_id': favoriteId,
            'logement_id': logementId,
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout aux favoris: $e');
    }
  }

  /// Retire un logement d'une liste de favoris spécifique
  Future<void> removeLogementFromFavorite(
    int favoriteId,
    int logementId,
  ) async {
    try {
      await _supabaseService.client
          .from(SupabaseConfig.favoriLogementsTable)
          .delete()
          .eq('favorite_id', favoriteId)
          .eq('logement_id', logementId);
    } catch (e) {
      throw Exception('Erreur lors du retrait des favoris: $e');
    }
  }

  /// Retire un logement de toutes les listes de favoris
  Future<void> removeLogementFromAllFavorites(
    int userId,
    int logementId,
  ) async {
    try {
      final listIds = await getFavoriteListsContainingLogement(
        userId,
        logementId,
      );

      for (final listId in listIds) {
        await removeLogementFromFavorite(listId, logementId);
      }
    } catch (e) {
      throw Exception('Erreur lors du retrait des favoris: $e');
    }
  }

  /// Renomme une liste de favoris
  Future<void> renameFavoriteList(int favoriteId, String newLibelle) async {
    try {
      await _supabaseService.client
          .from(SupabaseConfig.favoritesTable)
          .update({
            'libelle': newLibelle.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', favoriteId);
    } catch (e) {
      throw Exception('Erreur lors du renommage de la liste: $e');
    }
  }

  /// Supprime une liste de favoris
  Future<void> deleteFavoriteList(int favoriteId) async {
    try {
      // Supprimer d'abord tous les logements de la liste
      await _supabaseService.client
          .from(SupabaseConfig.favoriLogementsTable)
          .delete()
          .eq('favorite_id', favoriteId);

      // Puis supprimer la liste
      await _supabaseService.client
          .from(SupabaseConfig.favoritesTable)
          .delete()
          .eq('id', favoriteId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la liste: $e');
    }
  }

  /// Génère un lien de partage pour une liste
  Future<String> generateShareLink(int favoriteId) async {
    try {
      final shareLink = 'vodou://favorites/$favoriteId';

      await _supabaseService.client
          .from(SupabaseConfig.favoritesTable)
          .update({
            'lien_partage': shareLink,
            'est_partage': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', favoriteId);

      return shareLink;
    } catch (e) {
      throw Exception('Erreur lors de la génération du lien: $e');
    }
  }

  /// Récupère tous les logements d'une liste de favoris
  Future<List<Logement>> getLogementsFromFavoriteList(int favoriteId) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.favoriLogementsTable)
          .select('''
            *,
            logements!inner(
              *,
              photos:${SupabaseConfig.photosTable}(*)
            )
          ''')
          .eq('favorite_id', favoriteId);

      return (response as List).map((item) {
        final logementData = item['logements'] as Map<String, dynamic>;
        return Logement.fromJson(logementData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des logements: $e');
    }
  }

  /// Récupère tous les logements favoris de l'utilisateur (toutes listes confondues)
  Future<List<Logement>> getAllUserFavoriteLogements(int userId) async {
    try {
      final lists = await getUserFavoriteLists(userId);
      if (lists.isEmpty) return [];

      final listIds = lists.map((l) => l.id).toList();

      final response = await _supabaseService.client
          .from(SupabaseConfig.favoriLogementsTable)
          .select('''
            *,
            logements!inner(
              *,
              photos:${SupabaseConfig.photosTable}(*)
            )
          ''')
          .inFilter('favorite_id', listIds);

      // Utiliser un Set pour éviter les doublons
      final uniqueLogements = <int, Logement>{};
      for (final item in response as List) {
        final logementData = item['logements'] as Map<String, dynamic>;
        final logement = Logement.fromJson(logementData);
        uniqueLogements[logement.id] = logement;
      }

      return uniqueLogements.values.toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des favoris: $e');
    }
  }

  /// Récupère le nombre de logements dans une liste
  Future<int> getLogementCountInList(int favoriteId) async {
    try {
      final logements = await getLogementsFromFavoriteList(favoriteId);
      return logements.length;
    } catch (e) {
      return 0;
    }
  }

  /// Récupère le nombre total de logements favoris
  Future<int> getTotalFavoritesCount(int userId) async {
    try {
      final logements = await getAllUserFavoriteLogements(userId);
      return logements.length;
    } catch (e) {
      return 0;
    }
  }
}
