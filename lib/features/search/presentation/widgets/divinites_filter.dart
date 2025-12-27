import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/preferences/domain/models/user_preferences.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';

/// Filtre par divinités
class DivinitesFilter extends ConsumerStatefulWidget {
  const DivinitesFilter({super.key});

  @override
  ConsumerState<DivinitesFilter> createState() => _DivinitesFilterState();
}

class _DivinitesFilterState extends ConsumerState<DivinitesFilter> {
  final List<String> _selectedDivinites = [];

  @override
  void initState() {
    super.initState();
    final filters = ref.read(searchFiltersProvider);
    _selectedDivinites.addAll(filters.divinites);
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
                'Divinités',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez les divinités qui vous intéressent',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Grille de divinités
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: DiviniteType.values.length,
            itemBuilder: (context, index) {
              final divinite = DiviniteType.values[index];
              return _buildDiviniteCard(divinite);
            },
          ),

          const SizedBox(height: 24),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDivinites.clear();
                    });
                    ref.read(searchFiltersProvider.notifier).setDivinites([]);
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
                        .setDivinites(_selectedDivinites);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _selectedDivinites.isEmpty
                        ? 'Appliquer'
                        : 'Appliquer (${_selectedDivinites.length})',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiviniteCard(DiviniteType divinite) {
    final isSelected = _selectedDivinites.contains(divinite.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDivinites.remove(divinite.id);
          } else {
            _selectedDivinites.add(divinite.id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              divinite.nom,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }
}
