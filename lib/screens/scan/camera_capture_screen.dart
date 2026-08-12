import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF2E7D32); // Matches scan_screen.dart.

// Full-screen live camera preview for capturing a leaf photo in-app,
// instead of launching the system Camera app via image_picker. Keeping the
// app itself in the foreground the whole time means Android has no reason
// to kill the process mid-capture, unlike the old external-camera flow.
// After capture, shows the photo full-screen with Retake/Use Photo so the
// farmer can check quality (lighting, focus, framing) before committing to
// it. Returns the confirmed photo via Navigator.pop, or null if backed out.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  String? _error;
  bool _isCapturing = false;
  File? _reviewPhoto; // Set right after capture; null while previewing live.
  bool _photoConfirmed = false; // True once "Use Photo" hands it off.

  @override
  void initState() {
    super.initState();
    _initializeFuture = _setup();
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not access the camera. Check camera permission in '
              'your device settings, or try uploading from gallery instead.',
        );
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      // Pause the live preview while reviewing - the photo is a static
      // file at this point, so there's no need to keep the feed running.
      await controller.pausePreview();
      if (!mounted) return;
      setState(() => _reviewPhoto = File(photo.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not capture the photo. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _retake() async {
    await _controller?.resumePreview();
    _deleteFile(_reviewPhoto); // Discarding this capture for a new one.
    if (mounted) setState(() => _reviewPhoto = null);
  }

  // Every file here is one our own capture wrote to the app's temp
  // directory, so it's always safe to delete - unlike ScanScreen, which
  // also handles gallery picks that may point at the user's real photos.
  void _deleteFile(File? file) {
    if (file == null) return;
    try {
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Best-effort - fine if it's already gone.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    // Only clean up if the photo was never handed off via "Use Photo" -
    // once confirmed, ScanScreen owns it and is responsible for it.
    if (!_photoConfirmed) _deleteFile(_reviewPhoto);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewPhoto = _reviewPhoto;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: reviewPhoto != null
            ? _buildReviewStep(reviewPhoto)
            : _error != null
            ? _buildError(_error!)
            : FutureBuilder<void>(
                future: _initializeFuture,
                builder: (context, snapshot) {
                  final controller = _controller;
                  if (snapshot.connectionState != ConnectionState.done ||
                      controller == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(controller),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Positioned(
                        bottom: 28,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _isCapturing ? null : _capture,
                            child: Container(
                              height: 76,
                              width: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white54,
                                  width: 4,
                                ),
                              ),
                              child: _isCapturing
                                  ? const Padding(
                                      padding: EdgeInsets.all(22),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // Shown right after capture so the farmer can check focus, lighting, and
  // framing before committing to the photo, instead of finding out it's
  // unusable only after the (mocked) analysis step.
  Widget _buildReviewStep(File photo) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(photo, fit: BoxFit.cover),
        Positioned(
          top: 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 28,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retake,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text(
                    'Retake',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _photoConfirmed = true;
                    Navigator.pop(context, photo);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Use Photo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
