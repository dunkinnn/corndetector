// A detection's location on the photo, as fractions (0.0-1.0) of the
// image so it's independent of display size. Absent for scans saved before
// this existed, or if the model didn't localize a given detection.
class DetectionBox {
  const DetectionBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  static DetectionBox? fromMap(Map<String, dynamic> map) {
    final left = map['box_left'] as num?;
    final top = map['box_top'] as num?;
    final width = map['box_width'] as num?;
    final height = map['box_height'] as num?;
    if (left == null || top == null || width == null || height == null) {
      return null;
    }
    return DetectionBox(
      left: left.toDouble(),
      top: top.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'box_left': left,
    'box_top': top,
    'box_width': width,
    'box_height': height,
  };
}

// A single detected region within a leaf photo: one nutrient
// classification with its own confidence, symptom, and recommendation. A
// scan holds one of these per leaf/region found in the photo.
class Detection {
  const Detection({
    required this.label,
    required this.confidence,
    required this.symptom,
    required this.fertilizer,
    required this.rate,
    required this.timing,
    required this.note,
    this.box,
  });

  final String label;
  final double confidence;
  final String symptom;
  final String fertilizer;
  final String rate;
  final String timing;
  final String note;
  final DetectionBox? box;

  bool get isHealthy => label == 'Healthy';

  factory Detection.fromMap(Map<String, dynamic> map) {
    return Detection(
      label: map['label'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      symptom: map['symptom'] as String,
      fertilizer: map['fertilizer'] as String,
      rate: map['rate'] as String,
      timing: map['timing'] as String,
      note: map['note'] as String,
      box: DetectionBox.fromMap(map),
    );
  }

  // Row to insert into scan_detections (scan_id is added by ScanService).
  Map<String, dynamic> toInsertMap() => {
    'label': label,
    'confidence': confidence,
    'symptom': symptom,
    'fertilizer': fertilizer,
    'rate': rate,
    'timing': timing,
    'note': note,
    ...?box?.toMap(),
  };
}

// A leaf photo scan: one or more detected regions, each independently
// classified. More than one detection happens when a photo contains more
// than one leaf or symptom area.
class ScanResult {
  const ScanResult({
    required this.id,
    required this.createdAt,
    required this.detections,
    this.imagePath,
  });

  final String id;
  final DateTime createdAt;
  final List<Detection> detections;
  final String? imagePath;

  // True only when every detection in this scan is Healthy - a scan mixing
  // a healthy leaf with a deficient one still counts as deficient overall.
  bool get isHealthy => detections.every((d) => d.isHealthy);

  // Highest-confidence non-healthy detection, or the first detection if the
  // whole scan is healthy. Used wherever only one representative result
  // fits, e.g. the Home screen's Latest Detection card.
  Detection get primaryDetection {
    final deficient = detections.where((d) => !d.isHealthy).toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return deficient.isNotEmpty ? deficient.first : detections.first;
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    final rawDetections = (map['scan_detections'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return ScanResult(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      imagePath: map['image_path'] as String?,
      detections: rawDetections.map(Detection.fromMap).toList(),
    );
  }
}
