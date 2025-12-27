import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/projet/domain/models/projet.dart';

/// Repository pour gérer les projets sociaux
class ProjetRepository {
  final SupabaseService _supabaseService;

  ProjetRepository(this._supabaseService);

  /// Récupère tous les projets actifs
  Future<List<Projet>> getAllProjets() async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.projetsTable)
          .select('''
            *,
            categorie:${SupabaseConfig.categoriesTable}(libelle)
          ''')
          .eq('actif', 'OUI')
          .order('date_debut', ascending: false);

      return (response as List)
          .map((json) => Projet.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des projets: $e');
    }
  }

  /// Récupère un projet par son ID
  Future<Projet?> getProjetById(int id) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.projetsTable)
          .select('''
            *,
            categorie:${SupabaseConfig.categoriesTable}(libelle)
          ''')
          .eq('id', id)
          .single();

      return Projet.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du projet: $e');
    }
  }

  /// Récupère les projets par catégorie
  Future<List<Projet>> getProjetsByCategorie(int categorieId) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.projetsTable)
          .select('''
            *,
            categorie:${SupabaseConfig.categoriesTable}(libelle)
          ''')
          .eq('categorie_id', categorieId)
          .eq('actif', 'OUI')
          .order('date_debut', ascending: false);

      return (response as List)
          .map((json) => Projet.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des projets par catégorie: $e',
      );
    }
  }

  /// Récupère les contributions d'un projet
  Future<List<Contribution>> getProjetContributions(int projetId) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.contributionsTable)
          .select('''
            *,
            projet:${SupabaseConfig.projetsTable}(titre),
            reservation:${SupabaseConfig.reservationsTable}(
              *,
              user:${SupabaseConfig.usersTable}(prenom, nom)
            )
          ''')
          .eq('projet_id', projetId)
          .order('date_contribue', ascending: false);

      return (response as List)
          .map((json) => Contribution.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des contributions: $e');
    }
  }

  /// Récupère les statistiques d'un projet
  Future<Map<String, dynamic>> getProjetStatistics(int projetId) async {
    try {
      final contributionsResponse = await _supabaseService.client
          .from(SupabaseConfig.contributionsTable)
          .select('montant_contribue')
          .eq('projet_id', projetId);

      final contributions = contributionsResponse as List;
      final double totalContributions = contributions.fold(
        0.0,
        (sum, item) => sum + (item['montant_contribue'] as num).toDouble(),
      );

      return {
        'total_contributions': totalContributions,
        'nb_contributions': contributions.length,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Récupère toutes les catégories
  Future<List<Categorie>> getAllCategories() async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.categoriesTable)
          .select()
          .eq('actif', 'OUI')
          .order('libelle');

      return (response as List)
          .map((json) => Categorie.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }
}
