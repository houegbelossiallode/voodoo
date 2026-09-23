import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/booking/presentation/providers/my_reservations_provider.dart';
import 'package:vodou/features/booking/domain/models/reservation.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/router/app_router.dart';
import 'package:vodou/features/home/presentation/pages/main_page.dart';
import 'package:vodou/core/error/error_mapper.dart';

/// Page pour afficher les réservations de l'utilisateur
class MyReservationsPage extends ConsumerWidget {
  const MyReservationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Mes réservations'),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Veuillez vous connecter pour voir vos réservations'),
            );
          }

          final reservationsAsync = ref.watch(myReservationsProvider(user.id));

          return reservationsAsync.when(
            data: (reservations) {
              if (reservations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myReservationsProvider(user.id));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 80,
                            color: AppColors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune réservation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vos réservations apparaîtront ici',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(bottomNavIndexProvider.notifier).state =
                                  0;
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              context.go(AppRouter.home);
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Explorer les logements'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myReservationsProvider(user.id));
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return _ReservationCard(reservation: reservation);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ErrorMapper.toMessage(error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(myReservationsProvider(user.id));
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text(ErrorMapper.toMessage(error))),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final statusColor = _getStatusColor(reservation.statut);
    final statusText = _getStatusText(reservation.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showReservationDetails(context, reservation);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reservation.logementTitre ?? 'Logement',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFormat.format(reservation.dateDebut)} - ${dateFormat.format(reservation.dateFin)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Nombre de nuits
              Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${reservation.nbNuits} nuit${reservation.nbNuits > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.people,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${reservation.nbVoyageurs} voyageur${reservation.nbVoyageurs > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Montant
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Montant total',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${reservation.montant.toStringAsFixed(0)} XOF',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              // Référence
              if (reservation.reference != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Réf: ${reservation.reference}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut.toUpperCase()) {
      case 'PAYE':
      case 'CONFIRMED':
        return Colors.green;
      case 'EN_ATTENTE':
      case 'PENDING':
        return Colors.orange;
      case 'ANNULE':
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return AppColors.grey;
    }
  }

  String _getStatusText(String statut) {
    switch (statut.toUpperCase()) {
      case 'PAYE':
        return 'Payé';
      case 'CONFIRMED':
        return 'Confirmé';
      case 'EN_ATTENTE':
      case 'PENDING':
        return 'En attente';
      case 'ANNULE':
      case 'CANCELLED':
        return 'Annulé';
      case 'COMPLETED':
        return 'Terminé';
      default:
        return statut;
    }
  }

  void _showReservationDetails(BuildContext context, Reservation reservation) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de drag
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                'Détails de la réservation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Logement
              _buildDetailRow(
                'Logement',
                reservation.logementTitre ?? 'N/A',
                Icons.home,
              ),
              const Divider(height: 32),

              // Dates
              _buildDetailRow(
                'Date d\'arrivée',
                dateFormat.format(reservation.dateDebut),
                Icons.login,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Date de départ',
                dateFormat.format(reservation.dateFin),
                Icons.logout,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Durée',
                '${reservation.nbNuits} nuit${reservation.nbNuits > 1 ? 's' : ''}',
                Icons.nightlight_round,
              ),
              const Divider(height: 32),

              // Voyageurs
              _buildDetailRow(
                'Nombre de voyageurs',
                '${reservation.nbVoyageurs} personne${reservation.nbVoyageurs > 1 ? 's' : ''}',
                Icons.people,
              ),
              const Divider(height: 32),

              // Paiement
              _buildDetailRow(
                'Montant total',
                '${reservation.montant.toStringAsFixed(0)} XOF',
                Icons.payment,
              ),
              const SizedBox(height: 16),
              if (reservation.modePaiement != null)
                _buildDetailRow(
                  'Mode de paiement',
                  reservation.modePaiement!.toUpperCase(),
                  Icons.credit_card,
                ),
              const SizedBox(height: 16),
              if (reservation.reference != null)
                _buildDetailRow(
                  'Référence',
                  reservation.reference!,
                  Icons.receipt,
                ),
              const Divider(height: 32),

              // Statut
              _buildDetailRow(
                'Statut',
                _getStatusText(reservation.statut),
                Icons.info,
                valueColor: _getStatusColor(reservation.statut),
              ),

              // Projet communautaire
              if (reservation.projetTitre != null) ...[
                const Divider(height: 32),
                _buildDetailRow(
                  'Projet soutenu',
                  reservation.projetTitre!,
                  Icons.volunteer_activism,
                  valueColor: AppColors.primary,
                ),
              ],

              const SizedBox(height: 32),

              // Bouton fermer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
