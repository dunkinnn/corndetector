import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/confidence.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';

// Stored scan photo with each detection's box drawn in its NPK color.
class ScanPhoto extends StatefulWidget {
  const ScanPhoto({
    super.key,
    required this.scan,
    this.showLabels = false,
    this.fitWhole = false,
    this.onAspect,
  });

  final ScanResult scan;

  // Adds a small "N 92%" tag on each box; off for small thumbnails.
  final bool showLabels;

  // Resolves the photo's real shape, so `onAspect` can size the frame to it
  // and the boxes follow any crop that is left.
  final bool fitWhole;

  // Called with the photo's width/height once it is known.
  final ValueChanged<double>? onAspect;

  @override
  State<ScanPhoto> createState() => _ScanPhotoState();
}

class _ScanPhotoState extends State<ScanPhoto> {
  Future<String>? _urlFuture;
  double? _aspect;

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
    _aspect = null;
    if (path == null) {
      _urlFuture = null;
      return;
    }
    final future = const ScanService().photoUrl(path);
    _urlFuture = future;
    if (widget.fitWhole) future.then(_resolveAspect).catchError((_) {});
  }

  // The photo's own width/height, used to map the boxes onto the crop.
  void _resolveAspect(String url) {
    NetworkImage(url).resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        final aspect = info.image.width / info.image.height;
        if (!mounted || _aspect == aspect) return;
        setState(() => _aspect = aspect);
        widget.onAspect?.call(aspect);
      }),
    );
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

  // Where BoxFit.cover puts the photo inside the frame: the size it is drawn
  // at, and its top-left offset, which is negative on a cropped axis. With a
  // frame that matches the photo's shape nothing is cropped.
  (Size, Offset) _drawnPhoto(Size frame) {
    final aspect = _aspect;
    if (aspect == null) return (frame, Offset.zero);
    final size = aspect >= frame.width / frame.height
        ? Size(frame.height * aspect, frame.height)
        : Size(frame.width, frame.width / aspect);
    return (
      size,
      Offset((frame.width - size.width) / 2, (frame.height - size.height) / 2),
    );
  }

  // Boxes are fractions of the whole photo, mapped onto the drawn photo.
  List<Widget> _boxes(Size frame) {
    final (size, offset) = _drawnPhoto(frame);
    return [
      for (final d in widget.scan.detections)
        if (d.box != null) _box(d, offset, size),
    ];
  }

  Widget _box(Detection d, Offset offset, Size size) {
    final left = offset.dx + d.box!.left * size.width;
    final top = offset.dy + d.box!.top * size.height;
    return Positioned(
      left: left,
      top: top,
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
          // Pushed in when the box starts off-screen, so the label stays
          // inside the visible part of the photo.
          if (widget.showLabels)
            _tag(d, left: max(5, 5 - left), top: max(5, 5 - top)),
        ],
      ),
    );
  }

  Widget _tag(Detection d, {required double left, required double top}) {
    final letter = AppColors.nutrientLetter(d.label);
    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.nutrient(d.label),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 6),
          ],
        ),
        child: Text(
          '${letter.isEmpty ? 'OK' : letter} \u00B7 '
          '${confidencePercent(d.confidence)}',
          style: const TextStyle(
            fontSize: 12,
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
