import 'package:vodou/core/config/supabase_config.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';
import 'package:vodou/core/error/error_mapper.dart';

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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des divinités',
      );
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

      return Divinite.fromJson(response);
    } catch (e) {
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération de la divinité',
      );
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
      throw ErrorMapper.map(
        e,
        StackTrace.current,
        'la récupération des divinités du logement',
      );
    }
  }
}
