import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/core/error/error_mapper.dart';

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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des logements',
      );
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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des logements recommandés',
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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération du logement',
      );
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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la recherche des logements',
      );
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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des logements par divinité',
      );
    }
  }

  /// Récupère les logements par liste d'IDs de divinités (pour les préférences)
  /// Filtre par disponibilité et retourne les logements triés par pertinence
  Future<List<Logement>> getLogementsByDiviniteNames(
    List<int> diviniteIds, {
    bool disponibleOnly = true,
    int limit = 20,
  }) async {
    try {
      AppLogger.d('🔍 Recherche logements pour divinités IDs: $diviniteIds');

      if (diviniteIds.isEmpty) {
        AppLogger.w('⚠️ Aucune divinité spécifiée');
        return [];
      }

      // Étape 1 : Récupérer les IDs des logements liés aux divinités choisies
      final diviniteLogementResponse = await _supabaseService.client
          .from('divinite_logement')
          .select('logement_id')
          .inFilter('divinite_id', diviniteIds);

      AppLogger.d('📊 Réponse divinite_logement: $diviniteLogementResponse');

      // Extraire les IDs uniques des logements
      final logementIds = <int>{};
      for (final row in diviniteLogementResponse as List) {
        final logementId = row['logement_id'] as int;
        logementIds.add(logementId);
      }

      AppLogger.d(
        '🏠 ${logementIds.length} logements liés aux divinités: $logementIds',
      );

      if (logementIds.isEmpty) {
        AppLogger.w('⚠️ Aucun logement trouvé pour ces divinités');
        return [];
      }

      // Étape 2 : Récupérer les logements avec ces IDs
      var query = _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*)
          ''')
          .inFilter('id', logementIds.toList())
          .eq('actif', 'OUI');

      // Filtrer par disponibilité si demandé
      if (disponibleOnly) {
        query = query.eq('disponibilite', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      AppLogger.d('📊 ${response.length} logements récupérés');

      // Convertir en objets Logement
      final logements = (response as List).map((json) {
        final logement = Logement.fromJson(json as Map<String, dynamic>);
        AppLogger.d('   ✅ Logement ${logement.id}: ${logement.titre}');
        return logement;
      }).toList();

      AppLogger.d('✅ ${logements.length} logements trouvés au total');
      return logements;
    } catch (e, stackTrace) {
      AppLogger.e('❌ Erreur: $e');
      AppLogger.d('📋 Stack trace: $stackTrace');
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des logements par divinités',
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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la vérification de disponibilité',
      );
    }
  }
}
