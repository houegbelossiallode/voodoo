import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/search/domain/models/search_filters.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Repository pour la recherche de logements
class SearchRepository {
  final SupabaseService _supabaseService;

  SearchRepository(this._supabaseService);

  /// Recherche des logements avec filtres
  Future<List<Logement>> searchLogements(SearchFilters filters) async {
    try {
      AppLogger.d('🔍 Recherche avec filtres: $filters');

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

      // Filtre par divinités (IDs)
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
              if (divinite != null && divinite['id'] != null) {
                final diviniteId = divinite['id'] as int;
                return filters.divinites.contains(diviniteId);
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

      AppLogger.d('✅ ${logements.length} logements trouvés');
      return logements;
    } catch (e) {
      AppLogger.e('❌ Erreur recherche: $e');
      throw ErrorMapper.map(e, StackTrace.current, 'la recherche');
    }
  }

  /// Filtre les logements par disponibilité de dates
  /// Utilise la même logique que checkAvailability du ReservationRepository
  Future<List<Logement>> _filterByDateDisponibilite(
    List<Logement> logements,
    DateTime dateDebut,
    DateTime dateFin,
  ) async {
    final availableLogements = <Logement>[];

    AppLogger.d(
      '🔍 Filtrage par dates: ${dateDebut.toIso8601String().split('T')[0]} → ${dateFin.toIso8601String().split('T')[0]}',
    );

    for (final logement in logements) {
      try {
        // 1. Vérifier dans la table logement_disponibilites
        final disponibilitesResponse = await _supabaseService.client
            .from(SupabaseConfig.logementDisponibilitesTable)
            .select()
            .eq('logement_id', logement.id)
            .eq('statut', 'disponible');

        final disponibilites = disponibilitesResponse as List;

        AppLogger.d(
          '   📋 Logement ${logement.id} (${logement.titre}): ${disponibilites.length} période(s) de disponibilité',
        );

        // Vérifier si les dates demandées sont couvertes par une période disponible
        bool isInAvailablePeriod = false;
        for (var dispo in disponibilites) {
          // Normaliser les dates pour comparer uniquement les jours (sans heures)
          final dispoDebut = DateTime(
            DateTime.parse(dispo['date_debut'] as String).year,
            DateTime.parse(dispo['date_debut'] as String).month,
            DateTime.parse(dispo['date_debut'] as String).day,
          );
          final dispoFin = DateTime(
            DateTime.parse(dispo['date_fin'] as String).year,
            DateTime.parse(dispo['date_fin'] as String).month,
            DateTime.parse(dispo['date_fin'] as String).day,
          );
          final reservDebut = DateTime(
            dateDebut.year,
            dateDebut.month,
            dateDebut.day,
          );
          final reservFin = DateTime(dateFin.year, dateFin.month, dateFin.day);

          AppLogger.d('      Période dispo: $dispoDebut → $dispoFin');
          AppLogger.d('      Dates demandées: $reservDebut → $reservFin');

          // Les dates de réservation doivent être complètement dans la période disponible
          // dateDebut >= dispoDebut ET dateFin <= dispoFin
          final debutOk =
              reservDebut.isAtSameMomentAs(dispoDebut) ||
              reservDebut.isAfter(dispoDebut);
          final finOk =
              reservFin.isAtSameMomentAs(dispoFin) ||
              reservFin.isBefore(dispoFin);

          AppLogger.d('      Début OK: $debutOk ($reservDebut >= $dispoDebut)');
          AppLogger.d('      Fin OK: $finOk ($reservFin <= $dispoFin)');

          if (debutOk && finOk) {
            isInAvailablePeriod = true;
            AppLogger.d('      ✅ Période valide trouvée');
            break;
          }
        }

        if (!isInAvailablePeriod) {
          AppLogger.e(
            '   ❌ Logement ${logement.id} (${logement.titre}): Aucune période de disponibilité ne couvre ces dates',
          );
          continue;
        }

        // 2. Vérifier s'il y a des réservations qui se chevauchent
        AppLogger.d('   🔍 Vérification des réservations existantes...');
        final dateDebutStr = dateDebut.toIso8601String().split('T')[0];
        final dateFinStr = dateFin.toIso8601String().split('T')[0];

        final reservationsResponse = await _supabaseService.client
            .from(SupabaseConfig.reservationsTable)
            .select('id, date_debut, date_fin, statut')
            .eq('logement_id', logement.id)
            .not('statut', 'in', '(cancelled,ANNULEE)')
            .lte('date_debut', dateFinStr)
            .gte('date_fin', dateDebutStr);

        final reservations = reservationsResponse as List;
        AppLogger.d('   📋 ${reservations.length} réservation(s) trouvée(s)');

        if (reservations.isNotEmpty) {
          for (var res in reservations) {
            AppLogger.d(
              '      Réservation #${res['id']}: ${res['date_debut']} → ${res['date_fin']} (${res['statut']})',
            );
          }
          AppLogger.e(
            '   ❌ Logement ${logement.id} (${logement.titre}): Conflit avec ${reservations.length} réservation(s)',
          );
          continue;
        }

        // Si on arrive ici, le logement est disponible
        AppLogger.d(
          '   ✅ Logement ${logement.id} (${logement.titre}): DISPONIBLE',
        );
        availableLogements.add(logement);
      } catch (e) {
        AppLogger.w(
          '⚠️ Erreur vérification dispo pour logement ${logement.id}: $e',
        );
        // En cas d'erreur, on n'inclut PAS le logement pour éviter les fausses disponibilités
      }
    }

    AppLogger.d(
      '📊 Résultat: ${availableLogements.length}/${logements.length} logements disponibles',
    );
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
      AppLogger.e('❌ Erreur suggestions: $e');
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
      AppLogger.e('❌ Erreur quartiers: $e');
      return [];
    }
  }
}
