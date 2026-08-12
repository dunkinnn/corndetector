// A persisted leaf scan result, one row in the `scans` table.
class ScanResult {
  const ScanResult({
    required this.id,
    required this.label,
    required this.confidence,
    required this.symptom,
    required this.fertilizer,
    required this.rate,
    required this.timing,
    required this.note,
    required this.createdAt,
    this.imagePath,
  });

  final String id;
  final String label;
  final double confidence;
  final String symptom;
  final String fertilizer;
  final String rate;
  final String timing;
  final String note;
  final DateTime createdAt;
  final String? imagePath;

  bool get isHealthy => label == 'Healthy';

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] as String,
      label: map['label'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      symptom: map['symptom'] as String,
      fertilizer: map['fertilizer'] as String,
      rate: map['rate'] as String,
      timing: map['timing'] as String,
      note: map['note'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      imagePath: map['image_path'] as String?,
    );
  }
}
