import 'package:flutter/material.dart';

import '../core/colors.dart';

// Round N / P / K badge styled after the logo dots; a check mark for Healthy.
class NutrientDot extends StatelessWidget {
  const NutrientDot({super.key, required this.label, this.size = 22});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = AppColors.nutrientLetter(label);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.nutrient(label),
        shape: BoxShape.circle,
      ),
      child: letter.isEmpty
          ? Icon(Icons.check_rounded, size: size * 0.6, color: Colors.white)
          : Text(
              letter,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.52,
                height: 1,
                color: Colors.white,
              ),
            ),
    );
  }
}
