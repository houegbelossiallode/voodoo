import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';
import 'package:vodou/features/search/presentation/widgets/date_range_selector.dart';
import 'package:vodou/features/search/presentation/widgets/guests_selector.dart';
import 'package:vodou/features/search/presentation/widgets/price_range_selector.dart';
import 'package:vodou/features/search/presentation/widgets/divinites_filter.dart';
import 'package:intl/intl.dart';
import 'package:vodou/core/utils/app_logger.dart';

/// Barre de recherche intégrée avec filtres dans la HomePage
class IntegratedSearchBar extends ConsumerWidget {
  const IntegratedSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);

    return Column(
      children: [
        // Barre de recherche principale
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Destination
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          AppLogger.d('🟢 Zone Destination cliquée');
                          _showDestinationPicker(context, ref);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              filters.destination ??
                                  'Où souhaitez-vous aller ?',
                              style: TextStyle(
                                fontSize: 14,
                                color: filters.destination != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (filters.destination != null)
                      InkWell(
                        onTap: () {
                          AppLogger.d('🔴 Bouton X Destination cliqué');
                          ref
                              .read(searchFiltersProvider.notifier)
                              .setDestination(null);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.clear, size: 20, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Dates
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          AppLogger.d('🟢 Zone Dates cliquée');
                          _showDatePicker(context, ref);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dates',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getDateRangeText(filters),
                              style: TextStyle(
                                fontSize: 14,
                                color: filters.dateDebut != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (filters.dateDebut != null || filters.dateFin != null)
                      InkWell(
                        onTap: () {
                          AppLogger.d('🔴 Bouton X Dates cliqué');
                          ref
                              .read(searchFiltersProvider.notifier)
                              .setDates(null, null);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.clear, size: 20, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Voyageurs
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          AppLogger.d('🟢 Zone Voyageurs cliquée');
                          _showGuestsSelector(context, ref);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voyageurs',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              filters.nbVoyageurs != null
                                  ? '${filters.nbVoyageurs} voyageur${filters.nbVoyageurs! > 1 ? 's' : ''}'
                                  : 'Combien de personnes ?',
                              style: TextStyle(
                                fontSize: 14,
                                color: filters.nbVoyageurs != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (filters.nbVoyageurs != null)
                      InkWell(
                        onTap: () {
                          AppLogger.d('🔴 Bouton X Voyageurs cliqué');
                          ref
                              .read(searchFiltersProvider.notifier)
                              .setNbVoyageurs(null);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.clear, size: 20, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Filtres rapides (chips)
        if (filters.hasFilters)
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  context,
                  icon: Icons.attach_money,
                  label: _getPriceRangeText(filters),
                  isActive: filters.prixMin != null || filters.prixMax != null,
                  onTap: () => _showPriceSelector(context, ref),
                  onClear: () => ref
                      .read(searchFiltersProvider.notifier)
                      .setPrixRange(null, null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  icon: Icons.auto_awesome,
                  label: filters.divinites.isEmpty
                      ? 'Divinités'
                      : '${filters.divinites.length} divinité${filters.divinites.length > 1 ? 's' : ''}',
                  isActive: filters.divinites.isNotEmpty,
                  onTap: () => _showDivinitesFilter(context, ref),
                  onClear: () =>
                      ref.read(searchFiltersProvider.notifier).setDivinites([]),
                ),
                const SizedBox(width: 8),
                // Bouton réinitialiser tout
                InkWell(
                  onTap: () {
                    ref.read(searchFiltersProvider.notifier).clearFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear_all, size: 16, color: AppColors.error),
                        SizedBox(width: 4),
                        Text(
                          'Tout effacer',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.greyLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isActive && onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  onClear();
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDateRangeText(filters) {
    if (filters.dateDebut == null && filters.dateFin == null) {
      return 'Quand partez-vous ?';
    }

    final dateFormat = DateFormat('dd MMM', 'fr_FR');

    if (filters.dateDebut != null && filters.dateFin != null) {
      return '${dateFormat.format(filters.dateDebut!)} - ${dateFormat.format(filters.dateFin!)}';
    } else if (filters.dateDebut != null) {
      return 'À partir du ${dateFormat.format(filters.dateDebut!)}';
    } else {
      return 'Jusqu\'au ${dateFormat.format(filters.dateFin!)}';
    }
  }

  String _getPriceRangeText(filters) {
    if (filters.prixMin == null && filters.prixMax == null) {
      return 'Prix';
    }

    if (filters.prixMin != null && filters.prixMax != null) {
      return '${filters.prixMin!.toInt()}-${filters.prixMax!.toInt()} XOF';
    } else if (filters.prixMin != null) {
      return 'Min ${filters.prixMin!.toInt()} XOF';
    } else {
      return 'Max ${filters.prixMax!.toInt()} XOF';
    }
  }

  void _showDestinationPicker(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(searchFiltersProvider).destination ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Destination',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Saisir une destination',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(searchFiltersProvider.notifier)
                        .setDestination(
                          controller.text.isNotEmpty ? controller.text : null,
                        );
                    Navigator.pop(context);
                  },
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
      ),
    );
  }

  void _showDatePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DateRangeSelector(),
    );
  }

  void _showGuestsSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const GuestsSelector(),
    );
  }

  void _showPriceSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const PriceRangeSelector(),
    );
  }

  void _showDivinitesFilter(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DivinitesFilter(),
    );
  }
}
