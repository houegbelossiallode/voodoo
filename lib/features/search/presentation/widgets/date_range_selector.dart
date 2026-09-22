import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Sélecteur de plage de dates pour la recherche
class DateRangeSelector extends ConsumerStatefulWidget {
  const DateRangeSelector({super.key});

  @override
  ConsumerState<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends ConsumerState<DateRangeSelector> {
  DateTime? _dateDebut;
  DateTime? _dateFin;
  DateTime _focusedDay = DateTime.now();
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final filters = ref.read(searchFiltersProvider);
      _dateDebut = filters.dateDebut;
      _dateFin = filters.dateFin;
      if (_dateDebut != null) {
        _focusedDay = _dateDebut!;
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de drag
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sélectionner les dates',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Affichage des dates sélectionnées
            if (_dateDebut != null || _dateFin != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Arrivée',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _dateDebut != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                      'fr_FR',
                                    ).format(_dateDebut!)
                                  : 'Non sélectionnée',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Départ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _dateFin != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                      'fr_FR',
                                    ).format(_dateFin!)
                                  : 'Non sélectionnée',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Calendrier
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 730)),
                    focusedDay: _focusedDay,
                    locale: 'fr_FR',
                    rangeStartDay: _dateDebut,
                    rangeEndDay: _dateFin,
                    rangeSelectionMode: _rangeSelectionMode,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeStartDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeHighlightColor: AppColors.primary.withOpacity(0.2),
                      withinRangeDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!selectedDay.isBefore(
                        DateTime.now().subtract(const Duration(days: 1)),
                      )) {
                        setState(() {
                          _focusedDay = focusedDay;
                          if (_dateDebut == null || _dateFin != null) {
                            _dateDebut = selectedDay;
                            _dateFin = null;
                          } else if (selectedDay.isBefore(_dateDebut!)) {
                            _dateDebut = selectedDay;
                          } else {
                            _dateFin = selectedDay;
                          }
                        });
                      }
                    },
                    onRangeSelected: (start, end, focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        _dateDebut = start;
                        _dateFin = end;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Options flexibles
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Options rapides',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFlexibleOption('Weekend', 2),
                      _buildFlexibleOption('1 semaine', 7),
                      _buildFlexibleOption('2 semaines', 14),
                      _buildFlexibleOption('1 mois', 30),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Boutons d'action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _dateDebut = null;
                          _dateFin = null;
                        });
                        ref
                            .read(searchFiltersProvider.notifier)
                            .setDates(null, null);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Effacer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _dateDebut != null && _dateFin != null
                          ? () {
                              ref
                                  .read(searchFiltersProvider.notifier)
                                  .setDates(_dateDebut, _dateFin);
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Appliquer'),
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

  Widget _buildFlexibleOption(String label, int days) {
    final now = DateTime.now();
    final isSelected =
        _dateDebut != null &&
        _dateFin != null &&
        _dateDebut!.difference(now).inDays.abs() < 1 &&
        _dateFin!.difference(_dateDebut!).inDays == days;

    return InkWell(
      onTap: () {
        setState(() {
          _dateDebut = now;
          _dateFin = now.add(Duration(days: days));
          _focusedDay = now;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
