import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
import 'scan/camera_capture_screen.dart';

const Color _primaryColor = Color(0xFF2E7D32); // Modern Emerald Green
const Color _darkText = Color(0xFF1E293B);

enum _ScanStep { capture, analysis, result }

// Which source the "Add a Leaf Photo" bottom sheet was tapped for.
enum _ImageSource { camera, gallery }

// Choice offered when leaving an unsaved result (back gesture or bottom nav).
enum _LeaveAction { save, discard, cancel }

// Cycled during the analysis step so farmers see what's actually happening
// instead of a bare spinner. Purely cosmetic - the mock model doesn't run
// these as real substeps (see the TODO on _analyze).
const List<String> _analysisMessages = [
  'Reading leaf color pattern...',
  'Checking for Nitrogen signs...',
  'Checking for Phosphorus signs...',
  'Checking for Potassium signs...',
  'Comparing to a healthy leaf...',
];

// Fertilizer the system recommends for a given classification.
class _Recommendation {
  const _Recommendation({
    required this.fertilizer,
    required this.rate,
    required this.timing,
    required this.note,
  });

  final String fertilizer;
  final String rate;
  final String timing;
  final String note;
}

// One possible detection outcome. The model only detects and classifies;
// the recommendation below is derived from the resulting class. A scan can
// produce more than one of these when a photo has more than one leaf or
// symptom area (see _analyze).
class _ScanOutcome {
  const _ScanOutcome({
    required this.label,
    required this.confidence,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.symptom,
    required this.recommendation,
    required this.box,
  });

  final String label;
  final double confidence;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String symptom;
  final _Recommendation recommendation;
  final DetectionBox box; // Mocked until _analyze calls a real YOLOv8 detector.

  // Converts this mock outcome to the shared model saved via ScanService.
  Detection toDetection() => Detection(
    label: label,
    confidence: confidence,
    symptom: symptom,
    fertilizer: recommendation.fertilizer,
    rate: recommendation.rate,
    timing: recommendation.timing,
    note: recommendation.note,
    box: box,
  );
}

const List<_ScanOutcome> _mockOutcomes = [
  _ScanOutcome(
    label: 'Healthy',
    confidence: 0.94,
    color: _primaryColor,
    bgColor: Color(0xFFF0FDF4),
    icon: Icons.check_circle_rounded,
    symptom: 'Uniform green leaves with no visible discoloration.',
    recommendation: _Recommendation(
      fertilizer: 'No additional fertilizer needed',
      rate: 'Maintain current program',
      timing: 'Next scheduled application',
      note: 'Re-scan in 7 to 10 days to confirm the crop stays on track.',
    ),
    box: DetectionBox(left: 0.14, top: 0.16, width: 0.72, height: 0.68),
  ),
  _ScanOutcome(
    label: 'Nitrogen Deficiency',
    confidence: 0.88,
    color: Color(0xFFDC2626),
    bgColor: Color(0xFFFEF2F2),
    icon: Icons.grass_rounded,
    symptom: 'Yellowing along the midrib of older, lower leaves.',
    recommendation: _Recommendation(
      fertilizer: 'Urea (46-0-0)',
      rate: '2 to 3 bags per hectare',
      timing: 'Side-dress at V6 to V8, before tasseling',
      note: 'Apply to moist soil and cover lightly to reduce loss to the air.',
    ),
    box: DetectionBox(left: 0.30, top: 0.32, width: 0.42, height: 0.40),
  ),
  _ScanOutcome(
    label: 'Phosphorus Deficiency',
    confidence: 0.83,
    color: Color(0xFF0284C7),
    bgColor: Color(0xFFF0F9FF),
    icon: Icons.grass_rounded,
    symptom: 'Purple or reddish tint on leaf edges of young plants.',
    recommendation: _Recommendation(
      fertilizer: 'Solophos (0-18-0)',
      rate: '2 bags per hectare',
      timing: 'Band near the root zone at planting or early vegetative',
      note: 'Check soil pH; uptake drops sharply in strongly acidic soil.',
    ),
    box: DetectionBox(left: 0.06, top: 0.12, width: 0.30, height: 0.52),
  ),
  _ScanOutcome(
    label: 'Potassium Deficiency',
    confidence: 0.86,
    color: Color(0xFFE65100),
    bgColor: Color(0xFFFFF7ED),
    icon: Icons.grass_rounded,
    symptom: 'Yellow to brown scorching along the margins of older leaves.',
    recommendation: _Recommendation(
      fertilizer: 'Muriate of Potash (0-0-60)',
      rate: '1 to 2 bags per hectare',
      timing: 'Apply during early vegetative growth',
      note: 'Split the dose on sandy soil to limit leaching.',
    ),
    box: DetectionBox(left: 0.62, top: 0.14, width: 0.32, height: 0.56),
  ),
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.onRegisterLeaveGuard});

  // Called once this screen mounts, with a function the tab shell can call
  // before switching away from Scan to warn about an unsaved result - and
  // again with null on dispose. Only the shell's AppBottomNav needs this;
  // the back-gesture guard below is handled locally via PopScope.
  final void Function(Future<bool> Function()? guard)? onRegisterLeaveGuard;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  _ScanStep _step = _ScanStep.capture;
  File? _image;
  List<_ScanOutcome> _outcomes = []; // One entry per detected leaf/region.
  bool _isPicking = false; // Guards against double-taps re-entering the picker.
  bool _isSaving = false;
  bool _isSaved = false;

  // True only when `_image` is a temp file our own in-app camera wrote (see
  // camera_capture_screen.dart) - safe for us to delete. Gallery picks may
  // point at the user's actual photo library, so those are never deleted,
  // only ever dropped from our reference to them.
  bool _imageIsOwnedTempFile = false;

  Timer? _analysisTimer;
  int _analysisMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.onRegisterLeaveGuard?.call(_confirmLeaveIfUnsaved);
  }

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
                color: _primaryColor,
              ),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(sheetContext, _ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: _primaryColor,
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

  // Picks 1-3 mock detections for this photo, simulating a scan that finds
  // more than one leaf/symptom area. Healthy is never mixed with a
  // deficiency - a photo is either all-healthy or has one or more
  // deficiency detections, each a distinct label so their (also distinct)
  // mock boxes don't sit on top of each other.
  List<_ScanOutcome> _pickMockOutcomes() {
    final rng = Random();
    final healthy = _mockOutcomes.first;
    if (rng.nextDouble() < 0.35) return [healthy];
    final deficiencies = _mockOutcomes.skip(1).toList()..shuffle(rng);
    final count = 1 + rng.nextInt(deficiencies.length);
    return deficiencies.take(count).toList();
  }

  // Intentionally unused for now - the "Detect & Classify" button is
  // disabled until a real model replaces this. TODO: swap this simulated
  // delay + random pick for a real on-device or API-based
  // nutrient-deficiency detection model, then re-wire the button's
  // onPressed back to this.
  // ignore: unused_element
  Future<void> _analyze() async {
    if (_image == null) return;
    // Picked upfront (not after the delay) so the bounding boxes are
    // already known and can be drawn over the photo while the analysis
    // step "runs".
    final outcomes = _pickMockOutcomes();
    setState(() {
      _outcomes = outcomes;
      _step = _ScanStep.analysis;
      _analysisMessageIndex = 0;
    });
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted) return;
      setState(() {
        _analysisMessageIndex =
            (_analysisMessageIndex + 1) % _analysisMessages.length;
      });
    });
    await Future.delayed(const Duration(seconds: 2));
    _analysisTimer?.cancel();
    if (!mounted) return;
    setState(() => _step = _ScanStep.result);
    // Not saved yet - the farmer confirms with the Save Result button below,
    // so a result they don't want doesn't end up in their history.
  }

  // Saves the (mocked) results and photo to Supabase so they show up in
  // scan history and deficiency alerts. Only runs when the user taps Save
  // Result. One scan row is written with one detection row per outcome.
  Future<void> _saveResult() async {
    if (_outcomes.isEmpty || _isSaving || _isSaved) return;
    setState(() => _isSaving = true);
    try {
      await const ScanService().saveScan(
        detections: _outcomes.map((o) => o.toDetection()).toList(),
        photo: _image,
      );
      if (mounted) setState(() => _isSaved = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this result. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _hasUnsavedResult => _step == _ScanStep.result && !_isSaved;

  // Guards every way off this screen (back gesture, bottom nav, the center
  // FAB) so a completed-but-unsaved result never disappears silently - the
  // farmer has to actively choose to save or discard it first.
  Future<bool> _confirmLeaveIfUnsaved() async {
    if (!_hasUnsavedResult) return true;
    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsaved Scan Result'),
        content: const Text(
          "This result hasn't been saved yet. Leaving now will discard it.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveAction.discard),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, _LeaveAction.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    switch (action) {
      case _LeaveAction.save:
        await _saveResult();
        return _isSaved; // Only leave if the save actually went through.
      case _LeaveAction.discard:
        return true;
      case _LeaveAction.cancel:
      case null:
        return false;
    }
  }

  void _reset() {
    _analysisTimer?.cancel();
    _dropCurrentImage();
    setState(() {
      _step = _ScanStep.capture;
      _image = null;
      _outcomes = [];
      _isSaved = false;
    });
  }

  // Deletes `_image` from disk if (and only if) it's a temp file our own
  // in-app camera wrote - never a gallery pick, which may point at the
  // user's real photo library. Called whenever a photo is being replaced
  // or dropped without ever being saved, so captures don't pile up in the
  // device's temp storage.
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
    widget.onRegisterLeaveGuard?.call(null);
    _analysisTimer?.cancel();
    // Only clean up if the result was never saved - once _saveResult has
    // uploaded the photo, the local temp copy is left alone.
    if (!_isSaved) _dropCurrentImage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Blocks leaving (back gesture) while there's an unsaved result - the
    // tab shell guards bottom nav taps separately via onRegisterLeaveGuard.
    return PopScope(
      canPop: !_hasUnsavedResult,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _confirmLeaveIfUnsaved();
        if (!mounted) return;
        if (canLeave) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        extendBodyBehindAppBar: true,
        appBar: const AppTopBar(
          title: 'Detect & Classify',
          description: 'Identify the nutrient deficiency in a corn leaf',
          showProfile: false,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height:
                    MediaQuery.of(context).padding.top + AppTopBar.height + 20,
              ),
              _buildStepIndicator(),
              const SizedBox(height: 24),
              switch (_step) {
                _ScanStep.capture => _buildCaptureStep(),
                _ScanStep.analysis => _buildAnalysisStep(),
                _ScanStep.result => _buildResultStep(),
              },
              const SizedBox(height: 110), // Space to avoid bottom bar overlap
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 1: Photo capture/upload ---
  Widget _buildCaptureStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: double.infinity,
            height: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _image == null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder corner marks
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Icon(
                          Icons.crop_free_rounded,
                          size: 28,
                          color: _primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Icon(
                          Icons.crop_free_rounded,
                          size: 28,
                          color: _primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Icon(
                          Icons.crop_free_rounded,
                          size: 28,
                          color: _primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Icon(
                          Icons.crop_free_rounded,
                          size: 28,
                          color: _primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 36,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Add a Leaf Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Take a photo or upload one from your gallery',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // cacheWidth downsizes during decode so a full-res
                      // camera photo doesn't get decoded at full size just
                      // to render into this small preview box.
                      Image.file(_image!, fit: BoxFit.cover, cacheWidth: 800),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: _buildPillButton(
                          icon: Icons.refresh_rounded,
                          label: 'Change Photo',
                          onTap: _showImageSourceSheet,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick tip',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _darkText,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Use a clear close-up of one leaf in natural light. Fill most of the frame so the model can read the color and edges.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _darkText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          // Disabled until a real detection model is wired into _analyze -
          // see the TODO there. Capture/upload above still works normally.
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              disabledBackgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Detect & Classify',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Detection coming soon - the AI model isn\'t wired up yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  // --- Step 2: Analysis ---
  Widget _buildAnalysisStep() {
    final outcomes = _outcomes;
    return Column(
      children: [
        // Same photo-card treatment as the capture step, so this feels like
        // a continuation of the same flow rather than a different screen.
        Container(
          width: double.infinity,
          height: 360,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_image != null)
                Image.file(_image!, fit: BoxFit.cover, cacheWidth: 800),
              // Detection box(es) drawn directly on the photo as soon as
              // they're known (see _analyze), so it reads as "found here"
              // while the messages below cycle rather than only appearing
              // at the end. One box per detected leaf/region.
              for (final outcome in outcomes)
                _buildBoundingBoxOverlay(
                  outcome.box,
                  outcome.color,
                  outcome.label,
                ),
              // Scrim so the caption below stays readable over any photo.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // Cycles through _analysisMessages so it reads as
                      // active progress rather than a screen that's stuck.
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _analysisMessages[_analysisMessageIndex],
                          key: ValueKey(_analysisMessageIndex),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(
                    color: _primaryColor,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Detecting and classifying...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This usually takes just a few seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  color: _primaryColor,
                  backgroundColor: _primaryColor.withValues(alpha: 0.1),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 3: Result ---
  Widget _buildResultStep() {
    final outcomes = _outcomes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 360,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_image!, fit: BoxFit.cover, cacheWidth: 800),
                  for (final outcome in outcomes)
                    _buildBoundingBoxOverlay(
                      outcome.box,
                      outcome.color,
                      outcome.label,
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        if (outcomes.length > 1) ...[
          Text(
            '${outcomes.length} regions detected',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // --- One card + recommendation per detected region ---
        for (final outcome in outcomes) ...[
          _buildOutcomeCard(outcome),
          const SizedBox(height: 16),
          _buildRecommendationCard(outcome),
          const SizedBox(height: 20),
        ],

        if (_isSaved) ...[
          // Confirms the save actually happened, since there's no other
          // sign of it once the button is gone.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Saved to your history',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Scan Another Leaf',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                disabledBackgroundColor: _primaryColor.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Save Result',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Discard & Scan Another',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- Classification summary for one detected region ---
  Widget _buildOutcomeCard(_ScanOutcome outcome) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: outcome.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outcome.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(outcome.icon, color: outcome.color, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  outcome.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: outcome.color,
                  ),
                ),
              ),
              Text(
                '${(outcome.confidence * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: outcome.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            outcome.symptom,
            style: const TextStyle(fontSize: 13, color: _darkText, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- Fertilizer recommendation derived from the classification ---
  Widget _buildRecommendationCard(_ScanOutcome outcome) {
    final rec = outcome.recommendation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Fertilizer Recommendation',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationRow(
            Icons.inventory_2_outlined,
            'Fertilizer',
            rec.fertilizer,
          ),
          _buildRecommendationRow(Icons.straighten_rounded, 'Rate', rec.rate),
          _buildRecommendationRow(Icons.schedule_rounded, 'Timing', rec.timing),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.note,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Single labelled line inside the recommendation card.
  Widget _buildRecommendationRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _darkText,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modern Animated Capsule Step Indicator ---
  Widget _buildStepIndicator() {
    const steps = ['Photo', 'Classify', 'Result'];
    final currentIndex = _ScanStep.values.indexOf(_step);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final isPassed = currentIndex > i ~/ 2;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                color: isPassed ? _primaryColor : Colors.grey.shade200,
              ),
            );
          }
          final index = i ~/ 2;
          final isDone = index < currentIndex;
          final isActive = index == currentIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? _primaryColor
                  : (isDone
                        ? _primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : (isDone ? _primaryColor : Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? _primaryColor
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive || isDone
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : (isDone ? _primaryColor : Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Draws a detection box + label chip directly over the photo, positioned
  // as fractions of the container so it scales with any display size.
  Widget _buildBoundingBoxOverlay(DetectionBox box, Color color, String label) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned(
              left: box.left * constraints.maxWidth,
              top: box.top * constraints.maxHeight,
              width: box.width * constraints.maxWidth,
              height: box.height * constraints.maxHeight,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(7),
                        bottomRight: Radius.circular(7),
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
