import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';

/// Sélecteur du nombre de voyageurs
class GuestsSelector extends ConsumerStatefulWidget {
  const GuestsSelector({super.key});

  @override
  ConsumerState<GuestsSelector> createState() => _GuestsSelectorState();
}

class _GuestsSelectorState extends ConsumerState<GuestsSelector> {
  int _nbVoyageurs = 1;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(searchFiltersProvider);
    _nbVoyageurs = filters.nbVoyageurs ?? 1;
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
          // Barre de drag
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nombre de voyageurs',
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
            'Combien de personnes voyagent ?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Sélecteur de nombre avec design amélioré
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voyageurs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Maximum 20 personnes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _nbVoyageurs > 1
                            ? AppColors.primary
                            : AppColors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _nbVoyageurs > 1
                            ? () {
                                setState(() {
                                  _nbVoyageurs--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove, color: Colors.white),
                        iconSize: 20,
                      ),
                    ),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text(
                        '$_nbVoyageurs',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _nbVoyageurs < 20
                            ? AppColors.primary
                            : AppColors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _nbVoyageurs < 20
                            ? () {
                                setState(() {
                                  _nbVoyageurs++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add, color: Colors.white),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options rapides
          const Text(
            'Sélection rapide',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickOption(1),
              _buildQuickOption(2),
              _buildQuickOption(4),
              _buildQuickOption(6),
              _buildQuickOption(8),
              _buildQuickOption(10),
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
                      _nbVoyageurs = 1;
                    });
                    ref
                        .read(searchFiltersProvider.notifier)
                        .setNbVoyageurs(null);
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
                        .setNbVoyageurs(_nbVoyageurs);
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
        ],
      ),
    );
  }

  Widget _buildQuickOption(int count) {
    final isSelected = _nbVoyageurs == count;
    return InkWell(
      onTap: () {
        setState(() {
          _nbVoyageurs = count;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
