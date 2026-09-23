import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/widgets/custom_app_bar.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';
import 'package:vodou/features/search/presentation/widgets/destination_search_field.dart';
import 'package:vodou/features/search/presentation/widgets/date_range_selector.dart';
import 'package:vodou/features/search/presentation/widgets/guests_selector.dart';
import 'package:vodou/features/search/presentation/widgets/price_range_selector.dart';
import 'package:vodou/features/search/presentation/widgets/divinites_filter.dart';
import 'package:vodou/features/search/presentation/widgets/search_results_list.dart';

/// Page de recherche avancée de logements
class AdvancedSearchPage extends ConsumerStatefulWidget {
  const AdvancedSearchPage({super.key});

  @override
  ConsumerState<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends ConsumerState<AdvancedSearchPage> {
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Rechercher un logement',
        actions: [
          // Bouton pour afficher/masquer les filtres
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          // Badge du nombre de filtres actifs
          if (filters.activeFiltersCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filters.activeFiltersCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche principale
          _buildMainSearchBar(),

          // Filtres rapides (toujours visibles)
          _buildQuickFilters(),

          // Filtres avancés (affichables)
          if (_showFilters) _buildAdvancedFilters(),

          const Divider(height: 1),

          // Résultats de recherche
          Expanded(
            child: searchResults.when(
              data: (logements) {
                if (!filters.hasFilters) {
                  return _buildEmptyState();
                }
                if (logements.isEmpty) {
                  return _buildNoResultsState();
                }
                return SearchResultsList(logements: logements);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
      // Bouton flottant pour réinitialiser les filtres
      floatingActionButton: filters.hasFilters
          ? FloatingActionButton.extended(
              heroTag: 'search_fab',
              onPressed: () {
                ref.read(searchFiltersProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Réinitialiser'),
              backgroundColor: AppColors.error,
            )
          : null,
    );
  }

  Widget _buildMainSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: const DestinationSearchField(),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildQuickFilterChip(
              icon: Icons.calendar_today,
              label: 'Dates',
              onTap: () => _showDatePicker(),
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              icon: Icons.people,
              label: 'Voyageurs',
              onTap: () => _showGuestsSelector(),
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              icon: Icons.attach_money,
              label: 'Prix',
              onTap: () => _showPriceSelector(),
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              icon: Icons.auto_awesome,
              label: 'Divinités',
              onTap: () => _showDivinitesFilter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres avancés',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // TODO: Ajouter filtres équipements, langues, etc.
          const Text('Filtres supplémentaires à venir...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Commencez votre recherche',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Utilisez les filtres ci-dessus pour trouver\nvotre logement idéal',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun logement trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essayez de modifier vos critères de recherche',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(searchFiltersProvider.notifier).clearFilters();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réinitialiser les filtres'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes pour afficher les dialogues de filtres
  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DateRangeSelector(),
    );
  }

  void _showGuestsSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const GuestsSelector(),
    );
  }

  void _showPriceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const PriceRangeSelector(),
    );
  }

  void _showDivinitesFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DivinitesFilter(),
    );
  }
}
