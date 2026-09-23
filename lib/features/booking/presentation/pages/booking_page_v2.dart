import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vodou/core/widgets/app_image.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/features/auth/presentation/providers/auth_provider.dart';
import 'package:vodou/features/booking/presentation/providers/reservation_provider.dart';
import 'package:vodou/features/projet/presentation/providers/projet_provider.dart';
import 'package:vodou/features/projet/domain/models/projet.dart';
import 'package:vodou/features/home/domain/models/logement.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vodou/features/booking/presentation/widgets/availability_calendar_widget.dart';
import 'package:vodou/core/error/error_mapper.dart';

class BookingPageV2 extends ConsumerStatefulWidget {
  final Logement logement;

  const BookingPageV2({super.key, required this.logement});

  @override
  ConsumerState<BookingPageV2> createState() => _BookingPageV2State();
}

class _BookingPageV2State extends ConsumerState<BookingPageV2> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  bool _contributeToProject = false;
  Projet? _selectedProject;
  bool _isCheckingAvailability = false;
  bool _isAvailable = true;
  String? _availabilityMessage;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialiser la locale française pour le formatage des dates
    initializeDateFormatting('fr_FR', null);
  }

  @override
  void dispose() {
    super.dispose();
  }

  int get _nbNights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  double get _totalAmount {
    return widget.logement.prixParNuit * _nbNights;
  }

  double get _projectContribution {
    if (!_contributeToProject || _selectedProject == null) return 0.0;
    return _totalAmount * (_selectedProject!.pourcentageContribution / 100);
  }

  @override
  Widget build(BuildContext context) {
    final projetsAsync = ref.watch(allProjetsProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final reservationState = ref.watch(reservationNotifierProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Réservation'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Résumé du logement
            _buildAccommodationSummary(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Dates du séjour
            _buildSectionTitle('Dates du séjour'),
            const SizedBox(height: 16),
            AvailabilityCalendarWidget(
              logementId: widget.logement.id,
              onDateSelected: (date) {
                setState(() {
                  if (_checkIn == null ||
                      (_checkIn != null && _checkOut != null)) {
                    _checkIn = date;
                    _checkOut = null;
                  } else if (_checkIn != null && date.isAfter(_checkIn!)) {
                    _checkOut = date;
                  } else {
                    _checkIn = date;
                    _checkOut = null;
                  }
                });
                if (_checkIn != null && _checkOut != null) {
                  _checkAvailability();
                }
              },
            ),
            const SizedBox(height: 16),
            _buildDatesSelection(),

            const SizedBox(height: 24),

            // Nombre de voyageurs
            _buildSectionTitle('Nombre de voyageurs'),
            const SizedBox(height: 16),
            _buildGuestsSelection(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Projet communautaire
            _buildSectionTitle('Soutenir un projet communautaire'),
            const SizedBox(height: 8),
            Text(
              'Contribuez à un projet social local en ajoutant une petite participation à votre réservation',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              value: _contributeToProject,
              onChanged: (value) {
                setState(() {
                  _contributeToProject = value;
                  if (!value) _selectedProject = null;
                });
              },
              title: const Text('Je souhaite contribuer à un projet'),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),

            if (_contributeToProject) ...[
              const SizedBox(height: 16),
              projetsAsync.when(
                data: (projets) => _buildProjectSelection(projets),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(
                  ErrorMapper.toMessage(error),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Résumé des prix
            _buildPriceSummary(),

            const SizedBox(height: 32),

            // Message de disponibilité
            if (_availabilityMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isAvailable
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isAvailable ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAvailable ? Icons.check_circle : Icons.error,
                      color: _isAvailable ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _availabilityMessage!,
                        style: TextStyle(
                          color: _isAvailable
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bouton de réservation
            _isCheckingAvailability
                ? const Center(child: CircularProgressIndicator())
                : reservationState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _canBook()
                        ? () => _handleBooking(currentUser)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Confirmer et payer ${_totalAmount.toStringAsFixed(0)} XOF',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAccommodationSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppImage(
                url: widget.logement.firstPhotoUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.logement.titre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.logement.adresse ?? 'Ouidah, Bénin',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.logement.prixParNuit.toStringAsFixed(0)} XOF / nuit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDatesSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField('Arrivée', _checkIn, () => _selectDate(true)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateField('Départ', _checkOut, () => _selectDate(false)),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? DateFormat('dd MMM yyyy', 'fr_FR').format(date)
                  : 'Sélectionner',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary,
          ),
          Expanded(
            child: Text(
              '$_guests voyageur${_guests > 1 ? 's' : ''}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _guests++),
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelection(List<Projet> projets) {
    if (projets.isEmpty) {
      return const Text('Aucun projet disponible pour le moment');
    }

    // RadioGroup remplace groupValue/onChanged sur chaque Radio, dépréciés
    // depuis Flutter 3.32 : la sélection est désormais gérée par l'ancêtre.
    return RadioGroup<String>(
      groupValue: _selectedProject?.id,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedProject = projets.firstWhere((p) => p.id == value);
        });
      },
      child: Column(
        children: projets.map((projet) {
          final isSelected = _selectedProject?.id == projet.id;
          return Card(
            elevation: isSelected ? 4 : 1,
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedProject = projet),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Radio<String>(
                      value: projet.id,
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projet.titre,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            projet.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${projet.pourcentageContribution}% de contribution',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé des prix',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildPriceRow(
              '${widget.logement.prixParNuit.toStringAsFixed(0)} XOF x $_nbNights nuit${_nbNights > 1 ? 's' : ''}',
              _totalAmount,
            ),
            if (_contributeToProject && _selectedProject != null) ...[
              const SizedBox(height: 8),
              _buildPriceRow(
                'Contribution projet (${_selectedProject!.pourcentageContribution}%)',
                _projectContribution,
                isContribution: true,
              ),
            ],
            const Divider(height: 24),
            _buildPriceRow('Total', _totalAmount, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isContribution = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isContribution ? AppColors.secondary : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${amount.toStringAsFixed(0)} XOF',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal
                ? AppColors.primary
                : (isContribution ? AppColors.secondary : null),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isCheckIn) async {
    // Charger la liste stricte des dates disponibles depuis la base de données
    final availableDates = await ref
        .read(reservationRepositoryProvider)
        .getAvailableDates(widget.logement.id);

    if (!mounted) return;

    // Si aucune date disponible n'existe en BDD
    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Aucune date disponible pour ce logement pour le moment.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool isDateAvailable(DateTime day) {
      final normalizedDay = DateTime(day.year, day.month, day.day);
      return availableDates.any(
        (avail) =>
            avail.year == normalizedDay.year &&
            avail.month == normalizedDay.month &&
            avail.day == normalizedDay.day,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDate = isCheckIn
        ? today
        : (_checkIn != null
              ? DateTime(
                  _checkIn!.year,
                  _checkIn!.month,
                  _checkIn!.day,
                ).add(const Duration(days: 1))
              : today);

    // Filtrer les dates disponibles qui respectent minDate
    final validAvailableDates = availableDates.where((d) {
      final norm = DateTime(d.year, d.month, d.day);
      return !norm.isBefore(minDate);
    }).toList();

    validAvailableDates.sort((a, b) => a.compareTo(b));

    if (validAvailableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCheckIn
                ? '⚠️ Aucune date disponible pour ce logement.'
                : '⚠️ Aucune date de départ disponible après la date d\'arrivée sélectionnée.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Choisir une date initiale valide satisfaisant le predicate
    DateTime initialCandidate = isCheckIn
        ? (_checkIn ?? validAvailableDates.first)
        : (_checkOut ?? validAvailableDates.first);

    final normCandidate = DateTime(
      initialCandidate.year,
      initialCandidate.month,
      initialCandidate.day,
    );

    if (!isDateAvailable(normCandidate) || normCandidate.isBefore(minDate)) {
      initialCandidate = validAvailableDates.first;
    }

    final maxAvailableDate = validAvailableDates.last;
    final lastPickerDate =
        maxAvailableDate.isAfter(today.add(const Duration(days: 730)))
        ? maxAvailableDate
        : today.add(const Duration(days: 730));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialCandidate,
      firstDate: today,
      lastDate: lastPickerDate,
      selectableDayPredicate: (DateTime day) => isDateAvailable(day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(_checkIn!)) {
            _checkOut = null;
          }
        } else {
          if (_checkIn != null && picked.isAfter(_checkIn!)) {
            _checkOut = picked;
          }
        }
      });

      // Vérifier la disponibilité après sélection des dates
      if (_checkIn != null && _checkOut != null) {
        _checkAvailability();
      }
    }
  }

  bool _canBook() {
    // Vérifier les champs obligatoires
    if (_checkIn == null || _checkOut == null) return false;
    if (_guests <= 0) return false;
    if (widget.logement.nbVoyageurMax != null &&
        _guests > widget.logement.nbVoyageurMax!) {
      return false;
    }

    // Si l'utilisateur veut contribuer, un projet doit être sélectionné
    if (_contributeToProject && _selectedProject == null) return false;

    // Vérifier la disponibilité
    if (!_isAvailable) return false;

    return true;
  }

  /// Vérifie la disponibilité du logement
  Future<void> _checkAvailability() async {
    if (_checkIn == null || _checkOut == null) return;

    setState(() {
      _isCheckingAvailability = true;
      _availabilityMessage = null;
    });

    try {
      final isAvailable = await ref
          .read(reservationRepositoryProvider)
          .checkAvailability(
            logementId: widget.logement.id,
            dateDebut: _checkIn!,
            dateFin: _checkOut!,
          );

      setState(() {
        _isAvailable = isAvailable;
        _isCheckingAvailability = false;
        if (!isAvailable) {
          _availabilityMessage =
              '⚠️ Ce logement n\'est pas disponible pour ces dates. Veuillez choisir d\'autres dates.';
        } else {
          _availabilityMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _isCheckingAvailability = false;
        _availabilityMessage =
            '❌ Erreur lors de la vérification de disponibilité. Veuillez réessayer.';
      });
    }
  }

  Future<void> _handleBooking(dynamic currentUser) async {
    if (!_formKey.currentState!.validate()) return;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour réserver'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref
          .read(reservationNotifierProvider.notifier)
          .createReservationWithPayment(
            context: context,
            logementId: widget.logement.id,
            userId: currentUser.id,
            dateDebut: _checkIn!,
            dateFin: _checkOut!,
            montant: _totalAmount,
            nbNuits: _nbNights,
            nbVoyageurs: _guests,
            firstName: currentUser.prenom,
            lastName: currentUser.nom,
            email: currentUser.email,
            phone: currentUser.telephone,
            projetId: _selectedProject != null
                ? int.tryParse(_selectedProject!.id)
                : null,
          );

      // Attendre un peu pour que l'état soit mis à jour
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Vérifier l'état de la réservation
        final reservationState = ref.read(reservationNotifierProvider);

        reservationState.when(
          data: (reservation) {
            if (reservation != null) {
              // Paiement réussi et réservation créée
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Réservation confirmée avec succès !'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              context.pop();
            }
          },
          loading: () {
            // Ne rien faire, toujours en cours
          },
          error: (error, _) {
            // Paiement annulé ou échoué
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error.toString().contains('annulé')
                      ? 'Paiement annulé'
                      : ErrorMapper.toMessage(error),
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.toMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
