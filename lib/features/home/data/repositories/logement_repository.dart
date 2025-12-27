import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/logement.dart';

/// Repository pour gérer les logements
class LogementRepository {
  final SupabaseService _supabaseService;

  LogementRepository(this._supabaseService);

  /// Récupère tous les logements actifs avec leurs photos
  Future<List<Logement>> getAllLogements({int limit = 20}) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*)
          ''')
          .eq('actif', 'OUI')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Logement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des logements: $e');
    }
  }

  /// Récupère les logements recommandés avec leurs photos
  Future<List<Logement>> getRecommendedLogements({int limit = 10}) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*)
          ''')
          .eq('actif', 'OUI')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Logement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des logements recommandés: $e',
      );
    }
  }

  /// Récupère un logement par son ID avec ses photos
  Future<Logement?> getLogementById(int id) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*)
          ''')
          .eq('id', id)
          .single();

      return Logement.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du logement: $e');
    }
  }

  /// Recherche des logements par ville avec leurs photos
  Future<List<Logement>> searchLogementsByVille(
    String ville, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*)
          ''')
          .eq('actif', 'OUI')
          .ilike('ville', '%$ville%')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Logement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche des logements: $e');
    }
  }

  /// Récupère les logements par divinité avec leurs photos
  Future<List<Logement>> getLogementsByDivinite(
    int diviniteId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*),
            ${SupabaseConfig.diviniteLogementTable}!inner(divinite_id)
          ''')
          .eq('${SupabaseConfig.diviniteLogementTable}.divinite_id', diviniteId)
          .eq('actif', 'OUI')
          .limit(limit);

      return (response as List)
          .map((json) => Logement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des logements par divinité: $e',
      );
    }
  }

  /// Récupère les logements par liste de noms de divinités (pour les préférences)
  /// Filtre par disponibilité et retourne les logements triés par pertinence
  Future<List<Logement>> getLogementsByDiviniteNames(
    List<String> diviniteNames, {
    bool disponibleOnly = true,
    int limit = 20,
  }) async {
    try {
      print('🔍 Recherche logements pour divinités: $diviniteNames');

      // Requête avec jointure sur divinite_logement et divinites
      var query = _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*),
            divinite_logement!inner(
              divinites!inner(
                id,
                nom,
                description,
                image
              )
            )
          ''')
          .eq('actif', 'OUI');

      // Filtrer par disponibilité si demandé
      if (disponibleOnly) {
        query = query.eq('disponibilite', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      // Filtrer les résultats pour ne garder que ceux avec les divinités demandées
      final logements = (response as List)
          .map((json) => Logement.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filtrer par noms de divinités (case-insensitive)
      final filteredLogements = logements.where((logement) {
        final logementJson = response.firstWhere(
          (json) => json['id'] == logement.id,
          orElse: () => <String, dynamic>{},
        );

        if (logementJson['divinite_logement'] != null) {
          final divinitesData = logementJson['divinite_logement'] as List;
          return divinitesData.any((divLogement) {
            final divinite = divLogement['divinites'];
            if (divinite != null && divinite['nom'] != null) {
              final nom = (divinite['nom'] as String).toLowerCase();
              return diviniteNames.any(
                (prefNom) => nom == prefNom.toLowerCase(),
              );
            }
            return false;
          });
        }
        return false;
      }).toList();

      print('✅ ${filteredLogements.length} logements trouvés');
      return filteredLogements;
    } catch (e) {
      print('❌ Erreur: $e');
      throw Exception(
        'Erreur lors de la récupération des logements par divinités: $e',
      );
    }
  }

  /// Vérifie la disponibilité d'un logement pour une période donnée
  Future<bool> checkDisponibilite(
    int logementId,
    DateTime dateDebut,
    DateTime dateFin,
  ) async {
    try {
      // Vérifier d'abord la disponibilité générale
      final logement = await getLogementById(logementId);
      if (logement == null || !logement.disponibilite) {
        return false;
      }

      // Vérifier les périodes de disponibilité spécifiques
      final response = await _supabaseService.client
          .from(SupabaseConfig.logementDisponibilitesTable)
          .select()
          .eq('logement_id', logementId)
          .gte('date_fin', dateDebut.toIso8601String())
          .lte('date_debut', dateFin.toIso8601String());

      // Si aucune période bloquée, c'est disponible
      if (response.isEmpty) {
        return true;
      }

      // Vérifier si toutes les périodes sont disponibles
      final disponibilites = response as List;
      return disponibilites.every((dispo) => dispo['statut'] == 'disponible');
    } catch (e) {
      throw Exception('Erreur lors de la vérification de disponibilité: $e');
    }
  }
}
