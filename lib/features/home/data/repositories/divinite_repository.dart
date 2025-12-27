import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';

/// Repository pour gérer les divinités
class DiviniteRepository {
  final SupabaseService _supabaseService;

  DiviniteRepository(this._supabaseService);

  /// Récupère toutes les divinités
  Future<List<Divinite>> getAllDivinites() async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.divinitesTable)
          .select()
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Divinite.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des divinités: $e');
    }
  }

  /// Récupère une divinité par son ID
  Future<Divinite?> getDiviniteById(int id) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.divinitesTable)
          .select()
          .eq('id', id)
          .single();

      return Divinite.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la divinité: $e');
    }
  }

  /// Récupère les divinités associées à un logement
  Future<List<Divinite>> getDivinitesByLogementId(int logementId) async {
    try {
      final response = await _supabaseService.client
          .from(SupabaseConfig.divinitesTable)
          .select('''
            *,
            ${SupabaseConfig.diviniteLogementTable}!inner(logement_id)
          ''')
          .eq(
            '${SupabaseConfig.diviniteLogementTable}.logement_id',
            logementId,
          );

      return (response as List)
          .map((json) => Divinite.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des divinités du logement: $e',
      );
    }
  }
}
