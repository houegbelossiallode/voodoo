import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/services/supabase_service.dart';
import 'package:vodou/core/services/kkiapay_service.dart';
import 'package:vodou/features/booking/data/repositories/reservation_repository.dart';
import 'package:vodou/features/booking/domain/models/reservation.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Provider pour le service KKiaPay
final kkiaPayPaymentServiceProvider = Provider<KKiaPayService>((ref) {
  return KKiaPayService();
});

/// Provider pour le repository de réservation
final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(SupabaseService.instance);
});

/// Provider pour les réservations d'un utilisateur
final userReservationsProvider = FutureProvider.autoDispose
    .family<List<Reservation>, int>((ref, userId) async {
      final repository = ref.read(reservationRepositoryProvider);
      return repository.getUserReservations(userId);
    });

/// Provider pour une réservation spécifique
final reservationByIdProvider = FutureProvider.autoDispose
    .family<Reservation?, int>((ref, reservationId) async {
      final repository = ref.read(reservationRepositoryProvider);
      return repository.getReservationById(reservationId);
    });

/// Provider pour vérifier la disponibilité d'un logement
final checkAvailabilityProvider = FutureProvider.autoDispose
    .family<bool, Map<String, dynamic>>((ref, params) async {
      final repository = ref.read(reservationRepositoryProvider);
      return repository.checkAvailability(
        logementId: params['logementId'] as int,
        dateDebut: params['dateDebut'] as DateTime,
        dateFin: params['dateFin'] as DateTime,
      );
    });

/// State Notifier pour gérer le processus de réservation
class ReservationNotifier extends StateNotifier<AsyncValue<Reservation?>> {
  final ReservationRepository _repository;
  final KKiaPayService _paymentService;

  ReservationNotifier(this._repository, this._paymentService)
    : super(const AsyncValue.data(null));

  /// Crée une réservation avec paiement KKiaPay
  Future<void> createReservationWithPayment({
    required BuildContext context,
    required int logementId,
    required int userId,
    required DateTime dateDebut,
    required DateTime dateFin,
    required double montant,
    required int nbNuits,
    required int nbVoyageurs,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    int? projetId,
  }) async {
    state = const AsyncValue.loading();

    try {
      AppLogger.d('💳 Ouverture de la page de paiement KKiaPay...');

      // Lancer le paiement KKiaPay
      await _paymentService.startPayment(
        context: context,
        amount: montant,
        name: '$firstName $lastName',
        email: email,
        phone: phone,
        reason: 'Réservation logement #$logementId',
        onSuccess: (response, ctx) async {
          try {
            final transactionId = response['transactionId']?.toString() ?? '';
            final paymentStatus = response['status']?.toString() ?? '';

            // `response` contient l'identité du payeur : jamais journalisée.
            AppLogger.d('Paiement KKiaPay abouti', {'status': paymentStatus});

            // Créer la réservation dans Supabase avec les infos de paiement
            final reservation = await _repository.createReservation(
              logementId: logementId,
              userId: userId,
              dateDebut: dateDebut,
              dateFin: dateFin,
              montant: montant,
              nbNuits: nbNuits,
              nbVoyageurs: nbVoyageurs,
              modePaiement: 'kkiapay',
              reference: transactionId,
              projetId: projetId,
            );

            AppLogger.d('Réservation enregistrée', {'id': reservation.id});

            state = AsyncValue.data(reservation);

            // Fermer la page KKiaPay.
            // `ctx` traverse un await : sans cette garde, un utilisateur qui
            // quitte l'écran pendant l'écriture provoque un crash (VUL-16).
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e, stack) {
            AppLogger.e(
              'Échec de l\'enregistrement de la réservation',
              e,
              stack,
            );
            state = AsyncValue.error(e, stack);
            if (ctx.mounted) Navigator.pop(ctx);
          }
        },
        onFailed: (response, ctx) {
          final status = response['status']?.toString() ?? '';
          AppLogger.e('❌ Paiement échoué ou annulé');
          AppLogger.d('   Status: $status');
          AppLogger.d('   Response: $response');

          final errorMessage = status == 'PAYMENT_CANCELLED'
              ? 'Paiement annulé par l\'utilisateur'
              : 'Paiement échoué';

          state = AsyncValue.error(Exception(errorMessage), StackTrace.current);
          Navigator.pop(ctx);
        },
      );
    } catch (e, stack) {
      AppLogger.e('❌ Erreur lors du processus de réservation: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Annule une réservation
  Future<void> cancelReservation(int reservationId) async {
    try {
      await _repository.cancelReservation(reservationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Réinitialise l'état
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider pour le notifier de réservation
final reservationNotifierProvider =
    StateNotifierProvider<ReservationNotifier, AsyncValue<Reservation?>>((ref) {
      final repository = ref.read(reservationRepositoryProvider);
      final paymentService = ref.read(kkiaPayPaymentServiceProvider);

      return ReservationNotifier(repository, paymentService);
    });
