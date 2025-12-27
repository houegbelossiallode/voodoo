import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/accommodation/domain/models/logement.dart';

/// Repository pour gérer les logements avec Supabase
class LogementRepository {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Récupère tous les logements avec pagination
  Future<List<Logement>> getLogements({int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            user:${SupabaseConfig.usersTable}!user_id(nom, prenom, photo),
            pays:${SupabaseConfig.paysTable}!pays_id(libelle),
            type_logement:${SupabaseConfig.typeLogementsTable}!type_logement_id(libelle),
            photos:${SupabaseConfig.photosTable}(*),
            equipements:${SupabaseConfig.equipementLogementTable}(
              equipement:${SupabaseConfig.equipementsTable}(*)
            ),
            divinites:${SupabaseConfig.diviniteLogementTable}(
              divinite:${SupabaseConfig.divinitesTable}(*)
            ),
            rituels:${SupabaseConfig.rituelLogementTable}(
              rituel:${SupabaseConfig.rituelsTable}(*)
            ),
            pointforts:${SupabaseConfig.pointfortsTable}(*)
          ''')
          .eq('actif', 'OUI')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Logement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des logements: $e');
    }
  }

  /// Récupère un logement par son ID
  Future<Logement?> getLogementById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            user:${SupabaseConfig.usersTable}!user_id(nom, prenom, photo, telephone, email, langue),
            pays:${SupabaseConfig.paysTable}!pays_id(libelle),
            type_logement:${SupabaseConfig.typeLogementsTable}!type_logement_id(libelle),
            photos:${SupabaseConfig.photosTable}(*),
            equipements:${SupabaseConfig.equipementLogementTable}(
              equipement:${SupabaseConfig.equipementsTable}(*)
            ),
            divinites:${SupabaseConfig.diviniteLogementTable}(
              divinite:${SupabaseConfig.divinitesTable}(*)
            ),
            rituels:${SupabaseConfig.rituelLogementTable}(
              rituel:${SupabaseConfig.rituelsTable}(*)
            ),
            pointforts:${SupabaseConfig.pointfortsTable}(*)
          ''')
          .eq('id', id)
          .single();

      return Logement.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du logement: $e');
    }
  }

  /// Recherche de logements avec filtres
  Future<List<Logement>> searchLogements({
    String? destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int? nbVoyageurs,
    double? prixMin,
    double? prixMax,
    int? paysId,
    int? typeLogementId,
    List<int>? equipementIds,
    List<int>? diviniteIds,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            user:${SupabaseConfig.usersTable}!user_id(nom, prenom, photo),
            pays:${SupabaseConfig.paysTable}!pays_id(libelle),
            type_logement:${SupabaseConfig.typeLogementsTable}!type_logement_id(libelle),
            photos:${SupabaseConfig.photosTable}(*),
            equipements:${SupabaseConfig.equipementLogementTable}(
              equipement:${SupabaseConfig.equipementsTable}(*)
            ),
            divinites:${SupabaseConfig.diviniteLogementTable}(
              divinite:${SupabaseConfig.divinitesTable}(*)
            )
          ''')
          .eq('actif', 'OUI');

      // Filtres
      if (destination != null && destination.isNotEmpty) {
        query = query.ilike('adresse', '%$destination%');
      }

      if (paysId != null) {
        query = query.eq('pays_id', paysId);
      }

      if (typeLogementId != null) {
        query = query.eq('type_logement_id', typeLogementId);
      }

      if (nbVoyageurs != null) {
        query = query.gte('nb_voyageur_max', nbVoyageurs);
      }

      if (prixMin != null) {
        query = query.gte('prix_par_nuit', prixMin);
      }

      if (prixMax != null) {
        query = query.lte('prix_par_nuit', prixMax);
      }

      // TODO: Filtrer par disponibilité si checkIn et checkOut sont fournis
      // TODO: Filtrer par équipements et divinités via tables de liaison

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Logement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Récupère les logements d'un hôte
  Future<List<Logement>> getLogementsByHost(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            user:${SupabaseConfig.usersTable}!user_id(nom, prenom, photo),
            pays:${SupabaseConfig.paysTable}!pays_id(libelle),
            type_logement:${SupabaseConfig.typeLogementsTable}!type_logement_id(libelle),
            photos:${SupabaseConfig.photosTable}(*)
          ''')
          .eq('user_id', userId)
          .eq('actif', 'OUI')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Logement.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des logements de l\'hôte: $e',
      );
    }
  }

  /// Récupère les logements par divinité
  Future<List<Logement>> getLogementsByDivinite(int diviniteId) async {
    try {
      // Récupérer les IDs des logements liés à cette divinité
      final diviniteLogements = await _supabase
          .from(SupabaseConfig.diviniteLogementTable)
          .select('logement_id')
          .eq('divinite_id', diviniteId);

      final logementIds = (diviniteLogements as List)
          .map((e) => e['logement_id'])
          .toList();

      if (logementIds.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            user:${SupabaseConfig.usersTable}!user_id(nom, prenom, photo),
            pays:${SupabaseConfig.paysTable}!pays_id(libelle),
            type_logement:${SupabaseConfig.typeLogementsTable}!type_logement_id(libelle),
            photos:${SupabaseConfig.photosTable}(*),
            divinites:${SupabaseConfig.diviniteLogementTable}(
              divinite:${SupabaseConfig.divinitesTable}(*)
            )
          ''')
          .inFilter('id', logementIds)
          .eq('actif', 'OUI')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Logement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération par divinité: $e');
    }
  }

  /// Vérifie la disponibilité d'un logement
  Future<bool> checkDisponibilite({
    required String logementId,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      // Vérifier les réservations qui se chevauchent
      final reservations = await _supabase
          .from(SupabaseConfig.reservationsTable)
          .select('id')
          .eq('logement_id', logementId)
          .inFilter('statut', ['pending', 'confirmed'])
          .or(
            'date_debut.lte.${dateFin.toIso8601String().split('T')[0]},date_fin.gte.${dateDebut.toIso8601String().split('T')[0]}',
          );

      if ((reservations as List).isNotEmpty) {
        return false;
      }

      // Vérifier les disponibilités explicites
      final disponibilites = await _supabase
          .from(SupabaseConfig.logementDisponibilitesTable)
          .select('*')
          .eq('logement_id', logementId)
          .eq('statut', 'indisponible')
          .or(
            'date_debut.lte.${dateFin.toIso8601String().split('T')[0]},date_fin.gte.${dateDebut.toIso8601String().split('T')[0]}',
          );

      return (disponibilites as List).isEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de disponibilité: $e');
    }
  }

  /// Récupère les avis d'un logement
  Future<List<Map<String, dynamic>>> getAvisByLogement(
    String logementId,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.avisTable)
          .select('''
            *,
            user:${SupabaseConfig.usersTable}!user_id(nom, prenom, photo)
          ''')
          .eq('logement_id', logementId)
          .eq('actif', 'OUI')
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des avis: $e');
    }
  }

  /// Calcule la note moyenne d'un logement
  Future<double> getAverageRating(String logementId) async {
    try {
      final avis = await _supabase
          .from(SupabaseConfig.avisTable)
          .select('notes')
          .eq('logement_id', logementId)
          .eq('actif', 'OUI');

      if ((avis as List).isEmpty) {
        return 0.0;
      }

      final total = avis.fold<int>(
        0,
        (sum, item) => sum + (item['notes'] as int),
      );
      return total / avis.length;
    } catch (e) {
      throw Exception('Erreur lors du calcul de la note moyenne: $e');
    }
  }
}
