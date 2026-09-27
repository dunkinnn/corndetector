import 'package:flutter/material.dart';

// Palette taken from the MaisNutri logo: leaf, cob, soil line and NPK dots.
class AppColors {
  // Leaf greens.
  static const Color primary = Color(0xFF2E8B3E);
  static const Color primaryDark = Color(0xFF123D27);
  static const Color primaryLight = Color(0xFFE6F2E4);
  static const Color brandGreen = primary;

  // Corn cob yellow, used for the scan action and highlights.
  static const Color corn = Color(0xFFF5C21B);

  // NPK colors, matching the N, P and K dots in the logo.
  static const Color nitrogen = Color(0xFF1E7BD0);
  static const Color phosphorus = Color(0xFFF0701E);
  static const Color potassium = Color(0xFF8B3DA6);

  // Surfaces and text.
  static const Color background = Color(0xFFF5F3EC);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE4E0D4);
  static const Color textDark = Color(0xFF1B2A38);
  static const Color textMuted = Color(0xFF6C7166);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color errorRed = Color(0xFFD64545);

  // Color for a detection label, e.g. "Nitrogen Deficiency" or "Healthy".
  static Color nutrient(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('nitrogen')) return nitrogen;
    if (lower.contains('phosphorus')) return phosphorus;
    if (lower.contains('potassium')) return potassium;
    return primary;
  }

  // Single-letter badge for a detection label, empty for Healthy.
  static String nutrientLetter(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('nitrogen')) return 'N';
    if (lower.contains('phosphorus')) return 'P';
    if (lower.contains('potassium')) return 'K';
    return '';
  }
}

// Font families bundled in assets/fonts.
class AppFonts {
  static const String display = 'Bricolage';
  static const String body = 'Inter';
}
