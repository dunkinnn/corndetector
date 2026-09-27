import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../models/scan_result.dart';
import 'nutrient_dot.dart';

// One deficient detection with its NPK dot, symptom and scan date.
class DetectionAlertCard extends StatelessWidget {
  const DetectionAlertCard({
    super.key,
    required this.detection,
    required this.scanDate,
  });

  final Detection detection;
  final DateTime scanDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NutrientDot(label: detection.label, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detection.label,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '${(detection.confidence * 100).round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nutrient(detection.label),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  detection.symptom,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${scanDate.month}/${scanDate.day}/${scanDate.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
