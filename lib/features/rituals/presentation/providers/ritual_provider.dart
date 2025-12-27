import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/rituals/data/repositories/ritual_repository.dart';
import 'package:vodou/features/rituals/domain/models/ritual.dart';

/// Provider pour le repository des rituels
final ritualRepositoryProvider = Provider<RitualRepository>((ref) {
  return RitualRepository(SupabaseService.instance);
});

/// Provider pour récupérer tous les rituels
final allRitualsProvider = FutureProvider<List<Ritual>>((ref) async {
  final repository = ref.watch(ritualRepositoryProvider);
  return repository.getAllRituals();
});

/// Provider pour récupérer les rituels d'un logement
final logementRitualsProvider = FutureProvider.family<List<Ritual>, int>((
  ref,
  logementId,
) async {
  final repository = ref.watch(ritualRepositoryProvider);
  return repository.getLogementRituals(logementId);
});

/// Provider pour récupérer les détails d'un rituel
final ritualDetailsProvider = FutureProvider.family<Ritual?, int>((
  ref,
  ritualId,
) async {
  final repository = ref.watch(ritualRepositoryProvider);
  return repository.getRitualById(ritualId);
});

/// Provider pour récupérer les rituels d'une divinité
final diviniteRitualsProvider = FutureProvider.family<List<Ritual>, int>((
  ref,
  diviniteId,
) async {
  final repository = ref.watch(ritualRepositoryProvider);
  return repository.getRitualsByDivinite(diviniteId);
});

/// Provider pour rechercher des rituels
final searchRitualsProvider = FutureProvider.family<List<Ritual>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(ritualRepositoryProvider);
  return repository.searchRituals(query);
});

/// Provider pour récupérer les rituels disponibles
final availableRitualsProvider = FutureProvider<List<Ritual>>((ref) async {
  final repository = ref.watch(ritualRepositoryProvider);
  return repository.getAvailableRituals();
});

/// Provider pour gérer les rituels sélectionnés par l'utilisateur
final selectedRitualsProvider =
    StateNotifierProvider<SelectedRitualsNotifier, List<int>>((ref) {
      return SelectedRitualsNotifier();
    });

/// Notifier pour gérer les rituels sélectionnés
class SelectedRitualsNotifier extends StateNotifier<List<int>> {
  SelectedRitualsNotifier() : super([]);

  /// Ajoute un rituel à la sélection
  void addRitual(int ritualId) {
    if (!state.contains(ritualId)) {
      state = [...state, ritualId];
    }
  }

  /// Retire un rituel de la sélection
  void removeRitual(int ritualId) {
    state = state.where((id) => id != ritualId).toList();
  }

  /// Toggle un rituel (ajoute s'il n'est pas présent, retire sinon)
  void toggleRitual(int ritualId) {
    if (state.contains(ritualId)) {
      removeRitual(ritualId);
    } else {
      addRitual(ritualId);
    }
  }

  /// Vérifie si un rituel est sélectionné
  bool isSelected(int ritualId) {
    return state.contains(ritualId);
  }

  /// Vide la sélection
  void clearSelection() {
    state = [];
  }

  /// Retourne le nombre de rituels sélectionnés
  int get count => state.length;
}
