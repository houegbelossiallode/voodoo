import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';
import 'package:vodou/features/accommodation/domain/models/avis.dart';
import 'package:vodou/features/accommodation/domain/models/host_info.dart';
import 'package:vodou/features/accommodation/domain/models/equipement.dart';
import 'package:vodou/core/utils/app_logger.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Repository pour gérer les détails complets d'un logement
class AccommodationDetailsRepository {
  final SupabaseService _supabaseService;

  AccommodationDetailsRepository(this._supabaseService);

  /// Récupère les détails complets d'un logement avec toutes ses relations
  Future<Logement> getLogementDetails(int logementId) async {
    try {
      AppLogger.d('🔍 Récupération des détails du logement $logementId');

      final response = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('''
            *,
            photos:${SupabaseConfig.photosTable}(*),
            divinite_logement(
              divinites(*)
            ),
            equipement_logement(
              equipements(*)
            ),
            quartiers(
              id,
              libelle,
              latitude,
              longitude
            )
          ''')
          .eq('id', logementId)
          .single();

      AppLogger.d('✅ Détails récupérés');
      return Logement.fromJson(response);
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération des détails: $e');
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des détails du logement',
      );
    }
  }

  /// Récupère les divinités associées à un logement
  Future<List<Divinite>> getLogementDivinites(int logementId) async {
    try {
      final response = await _supabaseService.client
          .from('divinite_logement')
          .select('''
            divinites(*)
          ''')
          .eq('logement_id', logementId);

      final divinites = (response as List)
          .map((item) {
            final diviniteData = item['divinites'];
            if (diviniteData != null) {
              return Divinite.fromJson(diviniteData as Map<String, dynamic>);
            }
            return null;
          })
          .whereType<Divinite>()
          .toList();

      AppLogger.d('✅ ${divinites.length} divinités récupérées');
      return divinites;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération des divinités: $e');
      return [];
    }
  }

  /// Récupère les équipements d'un logement
  Future<List<Equipement>> getLogementEquipements(int logementId) async {
    try {
      final response = await _supabaseService.client
          .from('equipement_logement')
          .select('''
            equipements(*)
          ''')
          .eq('logement_id', logementId);

      final equipements = (response as List)
          .map((item) {
            final equipementData = item['equipements'];
            if (equipementData != null) {
              return Equipement.fromJson(
                equipementData as Map<String, dynamic>,
              );
            }
            return null;
          })
          .whereType<Equipement>()
          .toList();

      AppLogger.d('✅ ${equipements.length} équipements récupérés');
      return equipements;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération des équipements: $e');
      return [];
    }
  }

  /// Récupère les avis d'un logement
  Future<List<Avis>> getLogementAvis(int logementId) async {
    try {
      final response = await _supabaseService.client
          .from('avis')
          .select('*')
          .eq('logement_id', logementId)
          .order('created_at', ascending: false);

      final avisList = await Future.wait(
        (response as List).map((json) async {
          // Récupérer les infos utilisateur séparément
          final userId = json['user_id'];
          Map<String, dynamic>? userData;
          try {
            userData = await _supabaseService.client
                .from(SupabaseConfig.usersTable)
                .select('prenom, nom, photo')
                .eq('id', userId)
                .single();
          } catch (e) {
            AppLogger.w('⚠️ Erreur récupération user $userId: $e');
          }

          return Avis.fromJson({
            ...json,
            'note': (json['notes'] as num).toDouble(),
            'user_name': userData != null
                ? '${userData['prenom']} ${userData['nom']}'
                : 'Utilisateur',
            'user_photo': userData?['photo'],
          });
        }),
      );

      AppLogger.d('✅ ${avisList.length} avis récupérés');
      return avisList;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération des avis: $e');
      return [];
    }
  }

  /// Récupère les statistiques des avis
  Future<AvisStats> getAvisStats(int logementId) async {
    try {
      final response = await _supabaseService.client
          .from('avis')
          .select('notes')
          .eq('logement_id', logementId);

      final notes = (response as List)
          .map((item) => (item['notes'] as num).toDouble())
          .toList();

      if (notes.isEmpty) {
        return AvisStats(moyenneNote: 0.0, totalAvis: 0, repartitionNotes: {});
      }

      final moyenneNote = notes.reduce((a, b) => a + b) / notes.length;

      // Calculer la répartition des notes
      final repartition = <int, int>{};
      for (var i = 1; i <= 5; i++) {
        repartition[i] = notes.where((note) => note.round() == i).length;
      }

      return AvisStats(
        moyenneNote: moyenneNote,
        totalAvis: notes.length,
        repartitionNotes: repartition,
      );
    } catch (e) {
      AppLogger.e('❌ Erreur lors du calcul des statistiques: $e');
      return AvisStats(moyenneNote: 0.0, totalAvis: 0, repartitionNotes: {});
    }
  }

  /// Récupère les informations de l'hôte
  Future<HostInfo> getHostInfo(int userId) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.usersTable)
          .select('*')
          .eq('id', userId)
          .single();

      // Compter le nombre de logements de l'hôte
      final logementsCount = await _supabaseService.client
          .from(SupabaseConfig.logementsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('actif', 'OUI');

      // Récupérer les avis de tous les logements de l'hôte
      final logementIds = (logementsCount as List).map((l) => l['id']).toList();

      List avisResponse = [];
      if (logementIds.isNotEmpty) {
        avisResponse = await _supabaseService.client
            .from('avis')
            .select('notes')
            .inFilter('logement_id', logementIds);
      }

      double? noteGlobale;
      int nombreAvis = 0;

      if (avisResponse.isNotEmpty) {
        final notes = avisResponse
            .map((item) => (item['notes'] as num).toDouble())
            .toList();
        noteGlobale = notes.reduce((a, b) => a + b) / notes.length;
        nombreAvis = notes.length;
      }

      final hostInfo = HostInfo.fromJson({
        ...response,
        'nombre_logements': (logementsCount as List).length,
        'note_globale': noteGlobale,
        'nombre_avis': nombreAvis,
      });

      AppLogger.d('✅ Informations hôte récupérées');
      return hostInfo;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération des infos hôte: $e');
      throw Exception(
        'Erreur lors de la récupération des informations de l\'hôte: $e',
      );
    }
  }

  /// Récupère les informations du quartier
  Future<Map<String, dynamic>?> getQuartierInfo(int? quartierId) async {
    if (quartierId == null) return null;

    try {
      final response = await _supabaseService.client
          .from('quartiers')
          .select('*')
          .eq('id', quartierId)
          .single();

      return response;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération du quartier: $e');
      return null;
    }
  }

  /// Soumet un nouvel avis pour un logement
  Future<void> submitAvis({
    required int logementId,
    required int userId,
    required int note,
    required String commentaire,
  }) async {
    try {
      AppLogger.d('📝 Soumission d\'un avis pour le logement $logementId');

      await _supabaseService.client.from('avis').insert({
        'logement_id': logementId,
        'user_id': userId,
        'notes': note,
        'commentaire': commentaire,
        'actif': 'OUI',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.d('✅ Avis soumis avec succès');
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la soumission de l\'avis: $e');
      throw ErrorMapper.map(e, StackTrace.current, 'la soumission de l\'avis');
    }
  }
}
