import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/rituals/domain/models/ritual.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Repository pour gérer les rituels vaudou
class RitualRepository {
  final SupabaseService _supabaseService;

  RitualRepository(this._supabaseService);

  /// Récupère tous les rituels disponibles
  Future<List<Ritual>> getAllRituals() async {
    try {
      AppLogger.d('🔍 Récupération de tous les rituels');

      final response = await _supabaseService.client
          .from('rituels')
          .select('*')
          .eq('actif', 'OUI')
          .order('titre', ascending: true);

      final rituals = (response as List).map((json) {
        return Ritual.fromJson(json);
      }).toList();

      AppLogger.d('✅ ${rituals.length} rituels récupérés');
      return rituals;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération des rituels: $e');
      return [];
    }
  }

  /// Récupère les rituels d'un logement spécifique
  Future<List<Ritual>> getLogementRituals(int logementId) async {
    try {
      AppLogger.d('🔍 Récupération des rituels du logement $logementId');

      final response = await _supabaseService.client
          .from('rituel_logement')
          .select('''
            rituels(*)
          ''')
          .eq('logement_id', logementId);

      final rituals = (response as List)
          .where((item) => item['rituels'] != null)
          .map((item) {
            final ritualData = item['rituels'] as Map<String, dynamic>;
            return Ritual.fromJson(ritualData);
          })
          .toList();

      AppLogger.d('✅ ${rituals.length} rituels récupérés pour le logement');
      return rituals;
    } catch (e) {
      AppLogger.e(
        '❌ Erreur lors de la récupération des rituels du logement: $e',
      );
      return [];
    }
  }

  /// Récupère les détails d'un rituel spécifique
  Future<Ritual?> getRitualById(int ritualId) async {
    try {
      AppLogger.d('🔍 Récupération du rituel $ritualId');

      final response = await _supabaseService.client
          .from('rituels')
          .select('*')
          .eq('id', ritualId)
          .single();

      AppLogger.d('✅ Rituel récupéré');
      return Ritual.fromJson(response);
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la récupération du rituel: $e');
      return null;
    }
  }

  /// Récupère les rituels d'une divinité spécifique
  /// Note: La table rituels n'a pas de relation avec divinites dans le schéma actuel
  Future<List<Ritual>> getRitualsByDivinite(int diviniteId) async {
    try {
      AppLogger.d('🔍 Récupération des rituels de la divinité $diviniteId');

      // Cette fonctionnalité nécessite une table de liaison rituel_divinite
      // Pour l'instant, retourne une liste vide
      AppLogger.w(
        '⚠️ Fonctionnalité non disponible: pas de relation rituel-divinité',
      );
      return [];
    } catch (e) {
      AppLogger.e(
        '❌ Erreur lors de la récupération des rituels de la divinité: $e',
      );
      return [];
    }
  }

  /// Neutralise les métacaractères d'une expression de filtre PostgREST.
  ///
  /// Dans une chaîne passée à `.or(...)`, les caractères `,`, `(`, `)` et `.`
  /// sont structurants : une saisie utilisateur contenant par exemple
  /// `,id.gt.0` permet de sortir de l'expression prévue et de réécrire la
  /// clause `WHERE` (cf. AUDIT_SECURITE.md — VUL-07). Les jokers `%` et `_`
  /// sont également échappés pour que la recherche reste littérale.
  static String _sanitizeFilterValue(String input) {
    return input.replaceAll(RegExp(r'[,()\.%_\\"]'), ' ').trim();
  }

  /// Recherche des rituels par mot-clé
  Future<List<Ritual>> searchRituals(String query) async {
    try {
      AppLogger.d('Recherche de rituels');

      final safeQuery = _sanitizeFilterValue(query);
      if (safeQuery.isEmpty) return [];

      // TODO(sécurité): remplacer ce filtre construit à la main par un appel
      // RPC `search_rituels(p_query text)` — paramètre typé, aucune
      // interpolation dans l'expression de filtre.
      final response = await _supabaseService.client
          .from('rituels')
          .select('*')
          .or('titre.ilike.%$safeQuery%,description.ilike.%$safeQuery%')
          .eq('actif', 'OUI')
          .order('titre', ascending: true);

      final rituals = (response as List).map((json) {
        return Ritual.fromJson(json);
      }).toList();

      AppLogger.d('✅ ${rituals.length} rituels trouvés');
      return rituals;
    } catch (e) {
      AppLogger.e('❌ Erreur lors de la recherche de rituels: $e');
      return [];
    }
  }

  /// Récupère les rituels disponibles
  /// Note: La table rituels n'a pas de colonne 'disponible' dans le schéma actuel
  Future<List<Ritual>> getAvailableRituals() async {
    try {
      AppLogger.d('🔍 Récupération des rituels disponibles');

      final response = await _supabaseService.client
          .from('rituels')
          .select('*')
          .eq('actif', 'OUI')
          .order('titre', ascending: true);

      final rituals = (response as List).map((json) {
        return Ritual.fromJson(json);
      }).toList();

      AppLogger.d('✅ ${rituals.length} rituels disponibles');
      return rituals;
    } catch (e) {
      AppLogger.e(
        '❌ Erreur lors de la récupération des rituels disponibles: $e',
      );
      return [];
    }
  }
}
