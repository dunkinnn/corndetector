import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/deficiency_reference.dart';
import '../models/scan_result.dart';
import 'reference_data_service.dart';

// Thrown when YOLO finds no corn leaf in the photo.
class NoLeafDetectedException implements Exception {
  const NoLeafDetectedException();
}

// Which step of the scan failed, so the UI can say something accurate.
enum DetectionStage { loadModels, referenceData, inference }

class DetectionFailure implements Exception {
  const DetectionFailure(this.stage, this.cause);

  final DetectionStage stage;
  final Object cause;

  @override
  String toString() => 'DetectionFailure(${stage.name}): $cause';
}

// Runs on-device YOLOv8 leaf detection, then EfficientNet-B0 classification per leaf.
class DetectionService {
  const DetectionService();

  // False now that real models run; screens show a "Sample" notice when true.
  static const bool isSample = false;

  static const _yoloAsset = 'assets/models/yolov8_leaf.tflite';
  static const _classifierAsset = 'assets/models/efficientnet_b0.tflite';

  // Model bytes are read from assets once and reused for every scan.
  static Future<(Uint8List, Uint8List)>? _modelBytes;

  Future<List<Detection>> detect(File photo) async {
    final (Uint8List, Uint8List) models;
    try {
      _modelBytes ??= _loadModelBytes();
      models = await _modelBytes!;
    } catch (e) {
      // Don't cache a failed load, or every later scan fails the same way.
      _modelBytes = null;
      throw DetectionFailure(DetectionStage.loadModels, e);
    }
    final (yolo, classifier) = models;

    final List<DeficiencyReference> references;
    try {
      references = await const ReferenceDataService().getAll();
    } catch (e) {
      throw DetectionFailure(DetectionStage.referenceData, e);
    }
    final byLabel = {for (final r in references) r.label: r};

    final List<_Leaf> leaves;
    try {
      leaves = await Isolate.run(
        () => _analyze(photo.path, yolo, classifier),
      );
    } catch (e) {
      throw DetectionFailure(DetectionStage.inference, e);
    }
    debugPrint('[Detection] ${leaves.length} leaf/leaves: '
        '${leaves.map((l) => '${l.label} ${(l.confidence * 100).toStringAsFixed(1)}%').join(', ')}');
    if (leaves.isEmpty) throw const NoLeafDetectedException();

    final missing = {
      for (final l in leaves)
        if (!byLabel.containsKey(l.label)) l.label,
    };
    if (missing.isNotEmpty) {
      throw DetectionFailure(
        DetectionStage.referenceData,
        'deficiency_reference has no row for: ${missing.join(', ')} '
        '(got ${references.length} rows: ${byLabel.keys.join(', ')})',
      );
    }

    return [
      for (final leaf in leaves)
        if (byLabel[leaf.label] case final r?)
          Detection(
            label: r.label,
            confidence: leaf.confidence,
            symptom: r.symptom,
            fertilizer: r.fertilizer,
            rate: r.rate,
            timing: r.timing,
            note: r.note,
            box: leaf.box,
          ),
    ];
  }

  static Future<(Uint8List, Uint8List)> _loadModelBytes() async {
    Future<Uint8List> read(String asset) async =>
        (await rootBundle.load(asset)).buffer.asUint8List();
    return (await read(_yoloAsset), await read(_classifierAsset));
  }
}

// One classified leaf, passed back from the background isolate.
class _Leaf {
  const _Leaf(this.label, this.confidence, this.box);

  final String label;
  final double confidence;
  final DetectionBox box;
}

// Same order as the training folders, mapped to deficiency_reference labels.
const _classLabels = [
  'Healthy',
  'Nitrogen Deficiency',
  'Phosphorus Deficiency',
  'Potassium Deficiency',
];

const double _leafConfThreshold = 0.45;
const double _nmsIou = 0.45;

// Boxes this much inside a kept box are the same leaf seen twice.
const double _nmsContainment = 0.7;

// Softmax temperature for the classifier, fitted on the validation set with
// docs/calibration.md. Above 1.0 it softens the near-100% scores; 1.0 is raw.
const double _temperature = 1.0;
const int _maxSide = 1280;
const int _classifierSize = 224;

// Full pipeline, run off the UI thread: decode, detect, crop, classify.
List<_Leaf> _analyze(String path, Uint8List yoloBytes, Uint8List clsBytes) {
  var photo = img.decodeImage(File(path).readAsBytesSync());
  if (photo == null) throw const FormatException('Unreadable image.');
  photo = img.bakeOrientation(photo).convert(numChannels: 3);
  if (max(photo.width, photo.height) > _maxSide) {
    photo = photo.width >= photo.height
        ? img.copyResize(photo, width: _maxSide)
        : img.copyResize(photo, height: _maxSide);
  }

  final yolo = Interpreter.fromBuffer(yoloBytes);
  final classifier = Interpreter.fromBuffer(clsBytes);
  try {
    final boxes = _detectLeaves(yolo, photo);
    return [
      for (final b in boxes) _classify(classifier, photo, b),
    ];
  } finally {
    yolo.close();
    classifier.close();
  }
}

// Letterboxes to the YOLO input size, runs it, and returns boxes in photo pixels.
List<Rectangle<double>> _detectLeaves(Interpreter yolo, img.Image photo) {
  final size = yolo.getInputTensor(0).shape[1];
  final scale = min(size / photo.width, size / photo.height);
  final w = (photo.width * scale).round();
  final h = (photo.height * scale).round();
  final padX = (size - w) ~/ 2;
  final padY = (size - h) ~/ 2;

  final canvas = img.Image(width: size, height: size)
    ..clear(img.ColorRgb8(114, 114, 114));
  img.compositeImage(
    canvas,
    img.copyResize(photo, width: w, height: h, interpolation: img.Interpolation.linear),
    dstX: padX,
    dstY: padY,
  );

  final input = Float32List(size * size * 3);
  var i = 0;
  for (final p in canvas) {
    input[i++] = p.r / 255;
    input[i++] = p.g / 255;
    input[i++] = p.b / 255;
  }

  // Output is [1, 4 + classes, anchors] (or transposed); rows are cx, cy, w, h, scores.
  final shape = yolo.getOutputTensor(0).shape;
  final channelsFirst = shape[1] < shape[2];
  final channels = channelsFirst ? shape[1] : shape[2];
  final anchors = channelsFirst ? shape[2] : shape[1];
  final out = Float32List(channels * anchors);
  yolo.run(input.buffer, out.buffer);
  double at(int c, int a) =>
      channelsFirst ? out[c * anchors + a] : out[a * channels + c];

  // Newer exports emit coordinates normalized to 0-1; scale those back to pixels.
  var maxCoord = 0.0;
  for (var a = 0; a < anchors; a++) {
    maxCoord = max(maxCoord, at(2, a));
  }
  final coordScale = maxCoord <= 1.5 ? size.toDouble() : 1.0;

  final candidates = <(double, Rectangle<double>)>[];
  for (var a = 0; a < anchors; a++) {
    var score = 0.0;
    for (var c = 4; c < channels; c++) {
      score = max(score, at(c, a));
    }
    if (score < _leafConfThreshold) continue;
    final cx = (at(0, a) * coordScale - padX) / scale;
    final cy = (at(1, a) * coordScale - padY) / scale;
    final bw = at(2, a) * coordScale / scale;
    final bh = at(3, a) * coordScale / scale;
    final left = max(0.0, cx - bw / 2);
    final top = max(0.0, cy - bh / 2);
    final right = min(photo.width.toDouble(), cx + bw / 2);
    final bottom = min(photo.height.toDouble(), cy + bh / 2);
    if (right - left < 8 || bottom - top < 8) continue;
    candidates.add((score, Rectangle(left, top, right - left, bottom - top)));
  }
  return _nms(candidates);
}

// Keeps the highest-scoring box among heavily overlapping ones.
List<Rectangle<double>> _nms(List<(double, Rectangle<double>)> candidates) {
  candidates.sort((a, b) => b.$1.compareTo(a.$1));
  final kept = <Rectangle<double>>[];
  for (final (_, box) in candidates) {
    final overlaps = kept.any(
      (k) => _iou(k, box) >= _nmsIou || _containment(k, box) >= _nmsContainment,
    );
    if (!overlaps) kept.add(box);
  }
  return kept;
}

// Overlap as a fraction of the smaller box, so a box nested inside a much
// larger one still counts as a duplicate even when its IoU is low.
double _containment(Rectangle<double> a, Rectangle<double> b) {
  final inter = a.intersection(b);
  if (inter == null) return 0;
  final smaller = min(a.width * a.height, b.width * b.height);
  return smaller == 0 ? 0 : inter.width * inter.height / smaller;
}

double _iou(Rectangle<double> a, Rectangle<double> b) {
  final inter = a.intersection(b);
  if (inter == null) return 0;
  final i = inter.width * inter.height;
  return i / (a.width * a.height + b.width * b.height - i);
}

// Temperature scaling: softmax(logits / T) rewritten on probabilities, so a
// model that reports 100% on every leaf gives scores that match its accuracy.
List<double> _calibrate(Float32List probs) {
  if (_temperature == 1.0) return probs.toList();
  final powered = [
    for (final p in probs) pow(max(p, 1e-12), 1 / _temperature).toDouble(),
  ];
  final total = powered.reduce((a, b) => a + b);
  return [for (final p in powered) p / total];
}

// Crops one leaf, pads it like training preprocessing, and runs EfficientNet-B0.
_Leaf _classify(Interpreter classifier, img.Image photo, Rectangle<double> box) {
  final crop = img.copyCrop(
    photo,
    x: box.left.floor(),
    y: box.top.floor(),
    width: max(1, box.width.floor()),
    height: max(1, box.height.floor()),
  );
  final leaf = _padToSquare(crop, _classifierSize);

  // The Keras model normalizes internally, so pixels stay in the 0-255 range.
  final input = Float32List(_classifierSize * _classifierSize * 3);
  var i = 0;
  for (final p in leaf) {
    input[i++] = p.r.toDouble();
    input[i++] = p.g.toDouble();
    input[i++] = p.b.toDouble();
  }
  final probs = Float32List(_classLabels.length);
  classifier.run(input.buffer, probs.buffer);

  final scaled = _calibrate(probs);
  var best = 0;
  for (var c = 1; c < scaled.length; c++) {
    if (scaled[c] > scaled[best]) best = c;
  }
  return _Leaf(
    _classLabels[best],
    scaled[best],
    DetectionBox(
      left: box.left / photo.width,
      top: box.top / photo.height,
      width: box.width / photo.width,
      height: box.height / photo.height,
    ),
  );
}

// Matches the notebook's preprocess_leaf: keep aspect ratio, pad with the median edge color.
img.Image _padToSquare(img.Image crop, int size) {
  final scale = min(size / crop.width, size / crop.height);
  final w = max(1, (crop.width * scale).round());
  final h = max(1, (crop.height * scale).round());
  final resized = img.copyResize(
    crop,
    width: w,
    height: h,
    interpolation: img.Interpolation.cubic,
  );

  final r = <num>[], g = <num>[], b = <num>[];
  void addEdge(int x, int y) {
    final p = crop.getPixel(x, y);
    r.add(p.r);
    g.add(p.g);
    b.add(p.b);
  }

  for (var x = 0; x < crop.width; x++) {
    addEdge(x, 0);
    addEdge(x, crop.height - 1);
  }
  for (var y = 0; y < crop.height; y++) {
    addEdge(0, y);
    addEdge(crop.width - 1, y);
  }

  final canvas = img.Image(width: size, height: size)
    ..clear(img.ColorRgb8(_median(r), _median(g), _median(b)));
  return img.compositeImage(
    canvas,
    resized,
    dstX: (size - w) ~/ 2,
    dstY: (size - h) ~/ 2,
  );
}

int _median(List<num> values) {
  values.sort();
  final mid = values.length ~/ 2;
  return values.length.isOdd
      ? values[mid].toInt()
      : ((values[mid - 1] + values[mid]) / 2).floor();
}
