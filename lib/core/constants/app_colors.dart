import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Vodou Cultural Theme (Jaune foncé / Moutarde doré)
  static const Color primary = Color(0xFFD4A017); // Jaune foncé / Or moutarde
  static const Color primaryLight = Color(0xFFE8B923); // Jaune doré clair
  static const Color primaryDark = Color(0xFFB8860B); // Jaune foncé sombre

  // Secondary Colors
  static const Color secondary = Color(0xFFF4C430); // Jaune safran / Or vif
  static const Color secondaryLight = Color(0xFFFFD700); // Or brillant
  static const Color secondaryDark = Color(0xFFCC9900); // Jaune ambre

  // Accent Colors
  static const Color accent = Color(0xFF8B7500); // Jaune olive / Bronze
  static const Color accentLight = Color(0xFFA68B00); // Bronze clair
  static const Color accentDark = Color(0xFF6B5A00); // Bronze foncé

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF424242);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Special Colors
  static const Color favorite = Color(0xFFE91E63); // Rose pour favoris
  static const Color rating = Color(0xFFFFB300); // Jaune pour étoiles
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
