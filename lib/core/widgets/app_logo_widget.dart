import 'package:flutter/material.dart';
import 'package:vodou/core/constants/app_colors.dart';

/// Widget réutilisable pour afficher le logo de l'application
/// dans un cercle blanc avec ombre portée
class AppLogoWidget extends StatelessWidget {
  final double size;
  final double padding;

  const AppLogoWidget({super.key, this.size = 40, this.padding = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: Image.asset(
        'assets/logos/logo_2.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.home_outlined,
          color: AppColors.primary,
          size: size * 0.6,
        ),
      ),
    );
  }
}
