import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';
import 'package:vodou/features/accommodation/domain/models/avis.dart';
import 'package:vodou/features/accommodation/domain/models/host_info.dart';
import 'package:vodou/features/accommodation/domain/models/equipement.dart';
import 'package:vodou/features/accommodation/data/repositories/accommodation_details_repository.dart';

/// Provider du repository
final accommodationDetailsRepositoryProvider =
    Provider<AccommodationDetailsRepository>((ref) {
      final supabaseService = SupabaseService.instance;
      return AccommodationDetailsRepository(supabaseService);
    });

/// Provider pour les détails complets d'un logement
final logementDetailsProvider = FutureProvider.family<Logement, int>((
  ref,
  logementId,
) async {
  final repository = ref.watch(accommodationDetailsRepositoryProvider);
  return repository.getLogementDetails(logementId);
});

/// Provider pour les divinités d'un logement
final logementDivinitesProvider = FutureProvider.family<List<Divinite>, int>((
  ref,
  logementId,
) async {
  final repository = ref.watch(accommodationDetailsRepositoryProvider);
  return repository.getLogementDivinites(logementId);
});

/// Provider pour les équipements d'un logement
final logementEquipementsProvider =
    FutureProvider.family<List<Equipement>, int>((ref, logementId) async {
      final repository = ref.watch(accommodationDetailsRepositoryProvider);
      return repository.getLogementEquipements(logementId);
    });

/// Provider pour les avis d'un logement
final logementAvisProvider = FutureProvider.family<List<Avis>, int>((
  ref,
  logementId,
) async {
  final repository = ref.watch(accommodationDetailsRepositoryProvider);
  return repository.getLogementAvis(logementId);
});

/// Provider pour les statistiques des avis
final avisStatsProvider = FutureProvider.family<AvisStats, int>((
  ref,
  logementId,
) async {
  final repository = ref.watch(accommodationDetailsRepositoryProvider);
  return repository.getAvisStats(logementId);
});

/// Provider pour les informations de l'hôte
final hostInfoProvider = FutureProvider.family<HostInfo, int>((
  ref,
  userId,
) async {
  final repository = ref.watch(accommodationDetailsRepositoryProvider);
  return repository.getHostInfo(userId);
});

/// Provider pour les informations du quartier
final quartierInfoProvider = FutureProvider.family<Map<String, dynamic>?, int?>(
  (ref, quartierId) async {
    if (quartierId == null) return null;
    final repository = ref.watch(accommodationDetailsRepositoryProvider);
    return repository.getQuartierInfo(quartierId);
  },
);
