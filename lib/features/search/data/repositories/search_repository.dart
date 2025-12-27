import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/search/domain/models/search_filters.dart';

/// Repository pour la recherche de logements
class SearchRepository {
  final SupabaseService _supabaseService;

  SearchRepository(this._supabaseService);

  /// Recherche des logements avec filtres
  Future<List<Logement>> searchLogements(SearchFilters filters) async {
    try {
      print('🔍 Recherche avec filtres: $filters');

      // Construire la requête de base
      var query = _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*),
            divinite_logement(
              divinites(id, nom, description, image)
            ),
            equipement_logement(
              equipements(id, libelle)
            )
          ''')
          .eq('actif', 'OUI')
          .eq('disponibilite', true);

      // Filtre par destination (quartier)
      if (filters.destination != null && filters.destination!.isNotEmpty) {
        // Recherche dans l'adresse
        query = query.ilike('adresse', '%${filters.destination}%');
      }

      // Filtre par quartier ID
      if (filters.quartierId != null) {
        query = query.eq('quartier_id', filters.quartierId!);
      }

      // Filtre par nombre de voyageurs
      if (filters.nbVoyageurs != null) {
        query = query.gte('nb_voyageur_max', filters.nbVoyageurs!);
      }

      // Filtre par prix
      if (filters.prixMin != null) {
        query = query.gte('prix_par_nuit', filters.prixMin!);
      }
      if (filters.prixMax != null) {
        query = query.lte('prix_par_nuit', filters.prixMax!);
      }

      // Filtre par nombre de chambres
      if (filters.nbChambresMin != null) {
        query = query.gte('nb_chambre', filters.nbChambresMin!);
      }

      // Exécuter la requête
      final response = await query.order('created_at', ascending: false);

      // Parser les résultats
      var logements = (response as List)
          .map((json) => Logement.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filtres post-requête (car nécessitent des jointures complexes)

      // Filtre par divinités
      if (filters.divinites.isNotEmpty) {
        logements = logements.where((logement) {
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
                return filters.divinites.any(
                  (prefNom) => nom == prefNom.toLowerCase(),
                );
              }
              return false;
            });
          }
          return false;
        }).toList();
      }

      // Filtre par équipements
      if (filters.equipements.isNotEmpty) {
        logements = logements.where((logement) {
          final logementJson = response.firstWhere(
            (json) => json['id'] == logement.id,
            orElse: () => <String, dynamic>{},
          );

          if (logementJson['equipement_logement'] != null) {
            final equipementsData = logementJson['equipement_logement'] as List;
            final logementEquipementIds = equipementsData
                .map((eq) => eq['equipements']?['id'] as int?)
                .where((id) => id != null)
                .toList();

            // Vérifier que tous les équipements demandés sont présents
            return filters.equipements.every(
              (reqId) => logementEquipementIds.contains(reqId),
            );
          }
          return false;
        }).toList();
      }

      // Filtre par disponibilité de dates
      if (filters.dateDebut != null && filters.dateFin != null) {
        logements = await _filterByDateDisponibilite(
          logements,
          filters.dateDebut!,
          filters.dateFin!,
        );
      }

      print('✅ ${logements.length} logements trouvés');
      return logements;
    } catch (e) {
      print('❌ Erreur recherche: $e');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Filtre les logements par disponibilité de dates
  Future<List<Logement>> _filterByDateDisponibilite(
    List<Logement> logements,
    DateTime dateDebut,
    DateTime dateFin,
  ) async {
    final availableLogements = <Logement>[];

    for (final logement in logements) {
      try {
        // Vérifier les périodes de réservation
        final response = await _supabaseService.client
            .from(SupabaseConfig.logementDisponibilitesTable)
            .select()
            .eq('logement_id', logement.id)
            .gte('date_fin', dateDebut.toIso8601String())
            .lte('date_debut', dateFin.toIso8601String())
            .eq('statut', 'réservé'); // Seulement les périodes réservées

        // Si aucune réservation ne chevauche, le logement est disponible
        if (response.isEmpty) {
          availableLogements.add(logement);
        }
      } catch (e) {
        print('⚠️ Erreur vérification dispo pour logement ${logement.id}: $e');
        // En cas d'erreur, on inclut le logement par sécurité
        availableLogements.add(logement);
      }
    }

    return availableLogements;
  }

  /// Récupère les suggestions de destinations (quartiers)
  Future<List<String>> getDestinationSuggestions(String query) async {
    try {
      if (query.isEmpty) return [];

      // Rechercher dans les quartiers
      final quartiersResponse = await _supabaseService.client
          .from('quartiers')
          .select('libelle')
          .ilike('libelle', '%$query%')
          .limit(5);

      final quartiers = (quartiersResponse as List)
          .map((q) => q['libelle'] as String)
          .toList();

      // Rechercher dans les adresses de logements
      final logementsResponse = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('adresse')
          .ilike('adresse', '%$query%')
          .eq('actif', 'OUI')
          .limit(5);

      final adresses = (logementsResponse as List)
          .map((l) => l['adresse'] as String?)
          .where((a) => a != null && a.isNotEmpty)
          .cast<String>() // Cast pour éliminer les nulls
          .toSet() // Éliminer les doublons
          .toList();

      // Combiner et limiter
      final suggestions = [...quartiers, ...adresses].take(10).toList();

      return suggestions;
    } catch (e) {
      print('❌ Erreur suggestions: $e');
      return [];
    }
  }

  /// Récupère tous les quartiers
  Future<List<Map<String, dynamic>>> getQuartiers() async {
    try {
      final response = await _supabaseService.client
          .from('quartiers')
          .select('id, libelle, latitude, longitude')
          .order('libelle');

      return (response as List).map((q) => q as Map<String, dynamic>).toList();
    } catch (e) {
      print('❌ Erreur quartiers: $e');
      return [];
    }
  }
}
