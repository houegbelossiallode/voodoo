import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/booking/data/repositories/reservation_repository.dart';
import 'package:vodou/features/booking/presentation/providers/reservation_provider.dart';

/// Widget affichant un calendrier visuel des disponibilités du logement
class AvailabilityCalendarWidget extends ConsumerStatefulWidget {
  final int logementId;
  final Function(DateTime)? onDateSelected;

  const AvailabilityCalendarWidget({
    super.key,
    required this.logementId,
    this.onDateSelected,
  });

  @override
  ConsumerState<AvailabilityCalendarWidget> createState() =>
      _AvailabilityCalendarWidgetState();
}

class _AvailabilityCalendarWidgetState
    extends ConsumerState<AvailabilityCalendarWidget> {
  late DateTime _focusedMonth;
  Map<DateTime, DateAvailabilityStatus> _statusMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    setState(() => _isLoading = true);
    try {
      final statuses = await ref
          .read(reservationRepositoryProvider)
          .getDateStatuses(widget.logementId);
      if (mounted) {
        setState(() {
          _statusMap = statuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  DateAvailabilityStatus _getDayStatus(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _statusMap[normalizedDay] ?? DateAvailabilityStatus.indisponible;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre & Légende
            Text(
              'Aperçu des disponibilités',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLegend(),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            if (_isLoading)
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // En-tête Mois avec boutons de navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateFormat(
                      'MMMM yyyy',
                      'fr_FR',
                    ).format(_focusedMonth).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Jours de la semaine
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                        .map(
                          (d) => Expanded(
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 8),

              // Grille du mois
              _buildMonthGrid(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(Colors.green.shade600, 'Disponible'),
        _buildLegendItem(Colors.red.shade600, 'Réservé'),
        _buildLegendItem(Colors.grey.shade500, 'Indisponible'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Widget> dayWidgets = [];

    // Cases vides avant le 1er du mois
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Jours du mois
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isPast = date.isBefore(today);
      final status = _getDayStatus(date);

      Color bgColor = Colors.grey.shade100;
      Color textColor = Colors.grey.shade600;
      Color borderColor = Colors.transparent;

      if (isPast) {
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade400;
        borderColor = Colors.transparent;
      } else {
        switch (status) {
          case DateAvailabilityStatus.disponible:
            bgColor = Colors.green.shade50;
            textColor = Colors.green.shade900;
            borderColor = Colors.green.shade300;
            break;
          case DateAvailabilityStatus.reserver:
            bgColor = Colors.red.shade50;
            textColor = Colors.red.shade900;
            borderColor = Colors.red.shade300;
            break;
          case DateAvailabilityStatus.indisponible:
            bgColor = Colors.grey.shade200;
            textColor = Colors.grey.shade600;
            borderColor = Colors.grey.shade300;
            break;
        }
      }

      final isToday = date.isAtSameMomentAs(today);

      dayWidgets.add(
        InkWell(
          onTap: (!isPast && status == DateAvailabilityStatus.disponible)
              ? () => widget.onDateSelected?.call(date)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday ? AppColors.primary : borderColor,
                width: isToday ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? AppColors.primary : textColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }
}
