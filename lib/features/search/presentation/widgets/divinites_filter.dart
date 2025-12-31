import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';
import 'package:vodou/features/home/presentation/providers/home_provider.dart';
import 'package:vodou/features/home/domain/models/divinite.dart';

/// Filtre par divinités
class DivinitesFilter extends ConsumerStatefulWidget {
  const DivinitesFilter({super.key});

  @override
  ConsumerState<DivinitesFilter> createState() => _DivinitesFilterState();
}

class _DivinitesFilterState extends ConsumerState<DivinitesFilter> {
  final List<int> _selectedDivinites = [];

  @override
  void initState() {
    super.initState();
    final filters = ref.read(searchFiltersProvider);
    _selectedDivinites.addAll(filters.divinites);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Divinités',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedDivinites.isEmpty
                        ? 'Sélectionnez les divinités qui vous intéressent'
                        : '${_selectedDivinites.length} divinité${_selectedDivinites.length > 1 ? 's' : ''} sélectionnée${_selectedDivinites.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedDivinites.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      fontWeight: _selectedDivinites.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Grille de divinités scrollable
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Charger les divinités depuis la BD
                    ref
                        .watch(divinitesProvider)
                        .when(
                          data: (divinites) => GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.1,
                                ),
                            itemCount: divinites.length,
                            itemBuilder: (context, index) {
                              final divinite = divinites[index];
                              return _buildDiviniteCard(divinite);
                            },
                          ),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) =>
                              Center(child: Text('Erreur: $error')),
                        ),
                    const SizedBox(height: 24),
                  ],
                ),
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
                          _selectedDivinites.clear();
                        });
                        ref
                            .read(searchFiltersProvider.notifier)
                            .setDivinites([]);
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
                      onPressed: () {
                        ref
                            .read(searchFiltersProvider.notifier)
                            .setDivinites(_selectedDivinites);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiviniteCard(Divinite divinite) {
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 32,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              divinite.nom,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Icon(Icons.check_circle, size: 20, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
