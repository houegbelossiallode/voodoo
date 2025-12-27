import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';
import 'package:intl/intl.dart';

/// Sélecteur de plage de dates pour la recherche
class DateRangeSelector extends ConsumerStatefulWidget {
  const DateRangeSelector({super.key});

  @override
  ConsumerState<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends ConsumerState<DateRangeSelector> {
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(searchFiltersProvider);
    _dateDebut = filters.dateDebut;
    _dateFin = filters.dateFin;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 24),

          // Date de début
          _buildDateField(
            label: 'Date d\'arrivée',
            date: _dateDebut,
            onTap: () => _selectDate(context, true),
          ),

          const SizedBox(height: 16),

          // Date de fin
          _buildDateField(
            label: 'Date de départ',
            date: _dateFin,
            onTap: () => _selectDate(context, false),
          ),

          const SizedBox(height: 24),

          // Options flexibles
          const Text(
            'Options flexibles',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

          // Boutons d'action
          Row(
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
                  ),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null
                      ? DateFormat('dd MMM yyyy', 'fr_FR').format(date)
                      : 'Sélectionner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: date != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFlexibleOption(String label, int days) {
    return InkWell(
      onTap: () {
        final now = DateTime.now();
        setState(() {
          _dateDebut = now;
          _dateFin = now.add(Duration(days: days));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? (_dateDebut ?? DateTime.now())
        : (_dateFin ??
              _dateDebut?.add(const Duration(days: 1)) ??
              DateTime.now());

    final firstDate = isStartDate
        ? DateTime.now()
        : (_dateDebut ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
          // Si la date de fin est avant la nouvelle date de début, la réinitialiser
          if (_dateFin != null && _dateFin!.isBefore(picked)) {
            _dateFin = null;
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }
}
