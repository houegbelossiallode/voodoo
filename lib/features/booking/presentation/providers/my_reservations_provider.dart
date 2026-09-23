import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/features/booking/data/repositories/reservation_repository.dart';
import 'package:vodou/features/booking/domain/models/reservation.dart';

/// Provider pour le repository des réservations
final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(SupabaseService.instance);
});

/// Provider pour récupérer les réservations d'un utilisateur
final myReservationsProvider = FutureProvider.autoDispose
    .family<List<Reservation>, int>((ref, userId) async {
      final repository = ref.watch(reservationRepositoryProvider);
      return await repository.getUserReservations(userId);
    });
