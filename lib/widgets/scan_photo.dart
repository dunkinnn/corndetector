import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';

// Stored scan photo with each detection's box drawn in its NPK color.
class ScanPhoto extends StatefulWidget {
  const ScanPhoto({super.key, required this.scan, this.showLabels = false});

  final ScanResult scan;

  // Adds a small "N 92%" tag above each box; off for small thumbnails.
  final bool showLabels;

  @override
  State<ScanPhoto> createState() => _ScanPhotoState();
}

class _ScanPhotoState extends State<ScanPhoto> {
  Future<String>? _urlFuture;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  // Home reuses this widget when a newer scan arrives, so reload its photo.
  @override
  void didUpdateWidget(ScanPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scan.imagePath != widget.scan.imagePath) _loadUrl();
  }

  void _loadUrl() {
    final path = widget.scan.imagePath;
    _urlFuture = path == null ? null : const ScanService().photoUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryDark,
      child: _urlFuture == null
          ? _placeholder()
          : FutureBuilder<String>(
              future: _urlFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return _placeholder();
                return LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholder(),
                      ),
                      ..._boxes(constraints.biggest),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Box fractions assume the photo fills the frame, which BoxFit.cover gives.
  List<Widget> _boxes(Size size) {
    return [
      for (final d in widget.scan.detections)
        if (d.box != null)
          Positioned(
            left: d.box!.left * size.width,
            top: d.box!.top * size.height,
            width: d.box!.width * size.width,
            height: d.box!.height * size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.nutrient(d.label),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (widget.showLabels) _tag(d),
              ],
            ),
          ),
    ];
  }

  Widget _tag(Detection d) {
    final letter = AppColors.nutrientLetter(d.label);
    return Positioned(
      left: 0,
      top: -24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.nutrient(d.label),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${letter.isEmpty ? 'OK' : letter} \u00B7 ${(d.confidence * 100).round()}%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.eco_outlined, color: Color(0x66FFFFFF), size: 32),
    );
  }
}
