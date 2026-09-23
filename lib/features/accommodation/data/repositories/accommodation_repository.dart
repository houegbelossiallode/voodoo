import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/accommodation/domain/models/logement.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Repository pour gérer les logements avec Supabase
class AccommodationRepository {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Récupère tous les logements avec pagination
  Future<List<Logement>> getAccommodations({
    int limit = 20,
    int offset = 0,
  }) async {
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
          .eq('actif', 'OUI')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Logement.fromJson(json)).toList();
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des logements',
      );
    }
  }

  /// Récupère un logement par son ID
  Future<Logement?> getAccommodationById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            user:${SupabaseConfig.usersTable}!user_id(nom, prenom, photo, telephone, email),
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
            )
          ''')
          .eq('id', id)
          .single();

      return Logement.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération du logement',
      );
    }
  }

  /// Recherche de logements avec filtres
  Future<List<Logement>> searchAccommodations({
    String? destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    double? minPrice,
    double? maxPrice,
    List<String>? deities,
    List<String>? amenities,
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
            photos:${SupabaseConfig.photosTable}(*)
          ''')
          .eq('actif', 'OUI');

      // Filtres
      if (destination != null && destination.isNotEmpty) {
        query = query.ilike('adresse', '%$destination%');
      }

      if (guests != null) {
        query = query.gte('nb_voyageur_max', guests);
      }

      if (minPrice != null) {
        query = query.gte('prix_par_nuit', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('prix_par_nuit', maxPrice);
      }

      // TODO: Ajouter filtres pour deities et amenities (nécessite des tables de liaison)

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Logement.fromJson(json)).toList();
    } catch (e) {
      throw ErrorMapper.map(e, StackTrace.current, 'la recherche');
    }
  }

  /// Récupère les logements recommandés
  Future<List<Logement>> getRecommendedAccommodations({int limit = 10}) async {
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
          .eq('actif', 'OUI')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Logement.fromJson(json)).toList();
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des recommandations',
      );
    }
  }

  /// Récupère les logements par catégorie (divinité)
  Future<List<Logement>> getAccommodationsByDeity({
    required int diviniteId,
    int limit = 20,
  }) async {
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
          .limit(limit);

      return (response as List).map((json) => Logement.fromJson(json)).toList();
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération par divinité',
      );
    }
  }

  /// Vérifie la disponibilité d'un logement
  Future<bool> checkAvailability({
    required String logementId,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      // Vérifier s'il y a des réservations qui se chevauchent
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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la vérification de disponibilité',
      );
    }
  }
}
