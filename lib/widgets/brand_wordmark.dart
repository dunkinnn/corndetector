import 'package:flutter/material.dart';

import '../core/colors.dart';

// Two-tone "MaisNutri" wordmark: soil-dark "Mais", leaf-green "Nutri".
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 20});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        text: 'Mais',
        children: [
          TextSpan(
            text: 'Nutri',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -fontSize * 0.02,
        color: AppColors.textDark,
      ),
    );
  }
}
