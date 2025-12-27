import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/rituals/domain/models/ritual.dart';

/// Repository pour gérer les rituels vaudou
class RitualRepository {
  final SupabaseService _supabaseService;

  RitualRepository(this._supabaseService);

  /// Récupère tous les rituels disponibles
  Future<List<Ritual>> getAllRituals() async {
    try {
      print('🔍 Récupération de tous les rituels');

      final response = await _supabaseService.client
          .from('rituels')
          .select('*')
          .eq('actif', 'OUI')
          .order('titre', ascending: true);

      final rituals = (response as List).map((json) {
        return Ritual.fromJson(json);
      }).toList();

      print('✅ ${rituals.length} rituels récupérés');
      return rituals;
    } catch (e) {
      print('❌ Erreur lors de la récupération des rituels: $e');
      return [];
    }
  }

  /// Récupère les rituels d'un logement spécifique
  Future<List<Ritual>> getLogementRituals(int logementId) async {
    try {
      print('🔍 Récupération des rituels du logement $logementId');

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

      print('✅ ${rituals.length} rituels récupérés pour le logement');
      return rituals;
    } catch (e) {
      print('❌ Erreur lors de la récupération des rituels du logement: $e');
      return [];
    }
  }

  /// Récupère les détails d'un rituel spécifique
  Future<Ritual?> getRitualById(int ritualId) async {
    try {
      print('🔍 Récupération du rituel $ritualId');

      final response = await _supabaseService.client
          .from('rituels')
          .select('*')
          .eq('id', ritualId)
          .single();

      print('✅ Rituel récupéré');
      return Ritual.fromJson(response);
    } catch (e) {
      print('❌ Erreur lors de la récupération du rituel: $e');
      return null;
    }
  }

  /// Récupère les rituels d'une divinité spécifique
  /// Note: La table rituels n'a pas de relation avec divinites dans le schéma actuel
  Future<List<Ritual>> getRitualsByDivinite(int diviniteId) async {
    try {
      print('🔍 Récupération des rituels de la divinité $diviniteId');

      // Cette fonctionnalité nécessite une table de liaison rituel_divinite
      // Pour l'instant, retourne une liste vide
      print(
        '⚠️ Fonctionnalité non disponible: pas de relation rituel-divinité',
      );
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des rituels de la divinité: $e');
      return [];
    }
  }

  /// Recherche des rituels par mot-clé
  Future<List<Ritual>> searchRituals(String query) async {
    try {
      print('🔍 Recherche de rituels: $query');

      final response = await _supabaseService.client
          .from('rituels')
          .select('*')
          .or('titre.ilike.%$query%,description.ilike.%$query%')
          .eq('actif', 'OUI')
          .order('titre', ascending: true);

      final rituals = (response as List).map((json) {
        return Ritual.fromJson(json);
      }).toList();

      print('✅ ${rituals.length} rituels trouvés');
      return rituals;
    } catch (e) {
      print('❌ Erreur lors de la recherche de rituels: $e');
      return [];
    }
  }

  /// Récupère les rituels disponibles
  /// Note: La table rituels n'a pas de colonne 'disponible' dans le schéma actuel
  Future<List<Ritual>> getAvailableRituals() async {
    try {
      print('🔍 Récupération des rituels disponibles');

      final response = await _supabaseService.client
          .from('rituels')
          .select('*')
          .eq('actif', 'OUI')
          .order('titre', ascending: true);

      final rituals = (response as List).map((json) {
        return Ritual.fromJson(json);
      }).toList();

      print('✅ ${rituals.length} rituels disponibles');
      return rituals;
    } catch (e) {
      print('❌ Erreur lors de la récupération des rituels disponibles: $e');
      return [];
    }
  }
}
