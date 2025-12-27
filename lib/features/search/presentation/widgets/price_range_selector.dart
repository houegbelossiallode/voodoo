import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';

/// Sélecteur de fourchette de prix
class PriceRangeSelector extends ConsumerStatefulWidget {
  const PriceRangeSelector({super.key});

  @override
  ConsumerState<PriceRangeSelector> createState() => _PriceRangeSelectorState();
}

class _PriceRangeSelectorState extends ConsumerState<PriceRangeSelector> {
  RangeValues _priceRange = const RangeValues(5000, 50000);
  static const double _minPrice = 0;
  static const double _maxPrice = 100000;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(searchFiltersProvider);
    _priceRange = RangeValues(
      filters.prixMin ?? _minPrice,
      filters.prixMax ?? _maxPrice,
    );
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
                'Fourchette de prix',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Affichage de la fourchette sélectionnée
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceLabel('Min', _priceRange.start),
              const Text('-'),
              _buildPriceLabel('Max', _priceRange.end),
            ],
          ),

          const SizedBox(height: 16),

          // Slider de fourchette
          RangeSlider(
            values: _priceRange,
            min: _minPrice,
            max: _maxPrice,
            divisions: 20,
            activeColor: AppColors.primary,
            labels: RangeLabels(
              '${_priceRange.start.toInt()} XOF',
              '${_priceRange.end.toInt()} XOF',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),

          const SizedBox(height: 16),

          // Options rapides
          const Text(
            'Fourchettes suggérées',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickOption('Économique', 0, 15000),
              _buildQuickOption('Moyen', 15000, 35000),
              _buildQuickOption('Confort', 35000, 60000),
              _buildQuickOption('Luxe', 60000, 100000),
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
                      _priceRange = const RangeValues(_minPrice, _maxPrice);
                    });
                    ref
                        .read(searchFiltersProvider.notifier)
                        .setPrixRange(null, null);
                  },
                  child: const Text('Effacer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(searchFiltersProvider.notifier)
                        .setPrixRange(_priceRange.start, _priceRange.end);
                    Navigator.pop(context);
                  },
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

  Widget _buildPriceLabel(String label, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          '${price.toInt()} XOF',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickOption(String label, double min, double max) {
    final isSelected = _priceRange.start == min && _priceRange.end == max;

    return InkWell(
      onTap: () {
        setState(() {
          _priceRange = RangeValues(min, max);
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
