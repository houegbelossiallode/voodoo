import 'package:flutter/material.dart';
import 'package:vodou/core/constants/app_colors.dart';
import 'package:vodou/features/accommodation/domain/models/equipement.dart';

/// Section des équipements
class EquipementsSection extends StatelessWidget {
  final List<Equipement> equipements;

  const EquipementsSection({super.key, required this.equipements});

  @override
  Widget build(BuildContext context) {
    if (equipements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Équipements',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: equipements.map((equipement) {
            return _buildEquipementCard(context, equipement);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipementCard(BuildContext context, Equipement equipement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForEquipement(equipement.libelle),
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              equipement.libelle,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForEquipement(String libelle) {
    final lower = libelle.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi;
    } else if (lower.contains('clim') || lower.contains('air')) {
      return Icons.ac_unit;
    } else if (lower.contains('cuisine') || lower.contains('kitchen')) {
      return Icons.kitchen;
    } else if (lower.contains('parking')) {
      return Icons.local_parking;
    } else if (lower.contains('piscine') || lower.contains('pool')) {
      return Icons.pool;
    } else if (lower.contains('tv') || lower.contains('télé')) {
      return Icons.tv;
    } else if (lower.contains('lav')) {
      return Icons.local_laundry_service;
    } else if (lower.contains('jardin')) {
      return Icons.yard;
    }
    return Icons.check_circle_outline;
  }
}
