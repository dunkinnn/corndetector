import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../widgets/app_top_bar.dart';
import 'scan/camera_capture_screen.dart';

const Color _primaryColor = Color(0xFF2E7D32); // Modern Emerald Green
const Color _darkText = Color(0xFF1E293B);

enum _ScanStep { capture, comingSoon }

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

  // TODO: replace with a real on-device or API-based nutrient-deficiency
  // detection model. Until then, capture just leads to a coming-soon notice.
  void _analyze() {
    if (_image == null) return;
    setState(() => _step = _ScanStep.comingSoon);
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
    return Scaffold(
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
              _ScanStep.comingSoon => _buildComingSoonStep(),
            },
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
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
          child: ElevatedButton(
            onPressed: _image == null ? null : _analyze,
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
      ],
    );
  }

  // --- Step 2: Coming soon notice, shown instead of a (fake) result ---
  Widget _buildComingSoonStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: Image.file(_image!, fit: BoxFit.cover, cacheWidth: 800),
            ),
          ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
                child: const Icon(
                  Icons.science_rounded,
                  color: _primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Detection Model Coming Soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your photo looks good. The nutrient-deficiency detection model isn't ready yet, so there's no result to show for it.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: _reset,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Scan Another Leaf',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // --- Modern Animated Capsule Step Indicator ---
  Widget _buildStepIndicator() {
    const steps = ['Photo', 'Result'];
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
