import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../core/colors.dart';
import '../services/detection_service.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
import 'scan/camera_capture_screen.dart';
import 'scan_history_screen.dart';

const Color _darkText = AppColors.textDark;

enum _ScanStep { capture, analyzing }

// Which source the "Add a Leaf Photo" bottom sheet was tapped for.
enum _ImageSource { camera, gallery }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.onRegisterLeaveGuard});

  // Kept for API compatibility with RootTabScreen, which still wires this up
  // to guard bottom-nav taps away from Scan. Never invoked below since there
  // is no unsaved-result state to guard until real detection exists.
  final void Function(Future<bool> Function()? guard)? onRegisterLeaveGuard;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  _ScanStep _step = _ScanStep.capture;
  File? _image;
  bool _isPicking = false; // Guards against double-taps re-entering the picker.

  // True only when `_image` is a temp file our own in-app camera wrote (see
  // camera_capture_screen.dart) - safe for us to delete. Gallery picks may
  // point at the user's actual photo library, so those are never deleted,
  // only ever dropped from our reference to them.
  bool _imageIsOwnedTempFile = false;

  // Lets the user choose whether to take a new photo or upload an existing one.
  Future<void> _showImageSourceSheet() async {
    final choice = await showModalBottomSheet<_ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_rounded,
                color: _darkText,
              ),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(sheetContext, _ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: _darkText,
              ),
              title: const Text('Upload from Gallery'),
              onTap: () => Navigator.pop(sheetContext, _ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (choice == _ImageSource.camera) {
      await _openInAppCamera();
    } else if (choice == _ImageSource.gallery) {
      await _pickFromGallery();
    }
  }

  // In-app live camera preview (see camera_capture_screen.dart), used
  // instead of the system Camera app so this screen stays in the foreground
  // the whole time a photo is being taken.
  Future<void> _openInAppCamera() async {
    final photo = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (photo != null && mounted) {
      _dropCurrentImage(); // Replacing an existing pick, if any.
      setState(() {
        _image = photo;
        _imageIsOwnedTempFile = true;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      _dropCurrentImage(); // Replacing an existing pick, if any.
      setState(() {
        _image = File(picked.path);
        _imageIsOwnedTempFile = false; // May be the user's own gallery file.
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.code == 'photo_access_denied'
          ? 'Photo library access denied. Enable it in your device settings.'
          : 'Could not open the gallery. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _isPicking = false;
    }
  }

  // Runs detection, saves the scan, then opens its result screen.
  Future<void> _analyze() async {
    final image = _image;
    if (image == null || _step == _ScanStep.analyzing) return;
    setState(() => _step = _ScanStep.analyzing);
    try {
      final detections = await const DetectionService().detect(image);
      final scan = await const ScanService().saveScan(
        detections: detections,
        photo: image,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScanHistoryDetailScreen(scan: scan)),
      );
      if (mounted) _reset();
    } on NoLeafDetectedException {
      if (!mounted) return;
      setState(() => _step = _ScanStep.capture);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No corn leaf found. Retake the photo with the leaf filling the frame.',
          ),
        ),
      );
    } catch (e, st) {
      // Log the real cause - the old catch-all hid model/inference errors
      // behind a "check your connection" message.
      debugPrint('[Scan] analyze failed: $e\n$st');
      if (!mounted) return;
      setState(() => _step = _ScanStep.capture);
      final message = switch (e) {
        DetectionFailure(stage: DetectionStage.loadModels) =>
          'Could not load the detection model. Fully restart the app and try again.',
        DetectionFailure(stage: DetectionStage.inference) =>
          'Analysis failed on this photo. Try another photo.',
        DetectionFailure(stage: DetectionStage.referenceData) =>
          'Could not load nutrient reference data. Check your connection and try again.',
        _ => 'Could not save this scan. Check your connection and try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kDebugMode ? '$message\n\n$e' : message),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  void _reset() {
    _dropCurrentImage();
    setState(() {
      _step = _ScanStep.capture;
      _image = null;
    });
  }

  // Deletes `_image` from disk if (and only if) it's a temp file our own
  // in-app camera wrote - never a gallery pick, which may point at the
  // user's real photo library. Called whenever a photo is being replaced
  // or dropped. Keeps captures from piling up in the device's temp storage.
  void _dropCurrentImage() {
    final image = _image;
    if (image == null || !_imageIsOwnedTempFile) return;
    try {
      if (image.existsSync()) image.deleteSync();
    } catch (_) {
      // Best-effort - fine if it's already gone.
    }
  }

  @override
  void dispose() {
    _dropCurrentImage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCapture = _step == _ScanStep.capture;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + AppTopBar.height + 8,
          20,
          32,
        ),
        children: [
          Text(
            isCapture ? 'STEP 1 OF 2 \u00B7 PHOTO' : 'STEP 2 OF 2 \u00B7 ANALYZING',
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCapture ? 'Photograph a leaf' : 'Analyzing leaf',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.1,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 18),
          _buildCaptureStep(),
        ],
      ),
    );
  }

  // --- Step 1: Photo capture/upload ---
  Widget _buildCaptureStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _step == _ScanStep.analyzing ? null : _showImageSourceSheet,
            child: SizedBox(
              height: 340,
              child: _image == null ? _buildViewfinder() : _buildPreview(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: _darkText,
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For a good photo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'One leaf, natural light, filling most of the frame '
                      'so its color and edges are clear.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _image == null || _step == _ScanStep.analyzing
                ? null
                : _analyze,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.corn,
              foregroundColor: _darkText,
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(switch ((_image, _step)) {
              (null, _) => 'Add a photo to continue',
              (_, _ScanStep.analyzing) => 'Analyzing...',
              _ => 'Detect & Classify',
            }),
          ),
        ),
        if (DetectionService.isSample)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Sample mode: results are simulated until the detection model '
              'is trained.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  // Empty dark frame with corn-yellow corner marks and a scan prompt.
  Widget _buildViewfinder() {
    return Stack(
      children: [
        for (final corner in const [
          Alignment.topLeft,
          Alignment.topRight,
          Alignment.bottomLeft,
          Alignment.bottomRight,
        ])
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _CornerMark(corner: corner),
            ),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.corn,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 28,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap to add a leaf photo',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Take a photo or choose one from your gallery',
                style: TextStyle(fontSize: 13, color: Color(0xFFCFE2D4)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // cacheWidth downsizes during decode so a full-res photo stays cheap.
        Image.file(_image!, fit: BoxFit.cover, cacheWidth: 800),
        if (_step == _ScanStep.analyzing)
          const ColoredBox(
            color: Color(0x99123D27),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.corn),
                  SizedBox(height: 14),
                  Text(
                    'Checking for N, P and K deficiency',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Positioned(
            right: 12,
            top: 12,
            child: _buildPillButton(
              icon: Icons.refresh_rounded,
              label: 'Change photo',
              onTap: _showImageSourceSheet,
            ),
          ),
      ],
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// L-shaped viewfinder corner in corn yellow, oriented by its alignment.
class _CornerMark extends StatelessWidget {
  const _CornerMark({required this.corner});

  final Alignment corner;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.corn, width: 3);
    return SizedBox(
      width: 26,
      height: 26,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: corner.y < 0 ? side : BorderSide.none,
            bottom: corner.y > 0 ? side : BorderSide.none,
            left: corner.x < 0 ? side : BorderSide.none,
            right: corner.x > 0 ? side : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
