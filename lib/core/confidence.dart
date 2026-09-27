// Displayed percentage, kept faithful to the model: a score of 0.9998 shows
// as 99.9%, never rounded up to a 100% the classifier cannot back up.
String confidencePercent(double confidence) {
  final percent = (confidence * 100).clamp(0.1, 99.9);
  return percent >= 99
      ? '${percent.toStringAsFixed(1)}%'
      : '${percent.round()}%';
}

// How much weight to give a classifier result, from its calibrated score.
enum ConfidenceLevel { high, medium, low }

// Thresholds are on calibrated probabilities (see docs/calibration.md).
ConfidenceLevel confidenceLevel(double confidence) {
  if (confidence >= 0.85) return ConfidenceLevel.high;
  if (confidence >= 0.65) return ConfidenceLevel.medium;
  return ConfidenceLevel.low;
}

String confidenceWord(double confidence) => switch (confidenceLevel(
  confidence,
)) {
  ConfidenceLevel.high => 'High confidence',
  ConfidenceLevel.medium => 'Medium confidence',
  ConfidenceLevel.low => 'Low confidence',
};
