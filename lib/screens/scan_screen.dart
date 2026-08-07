import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';

const Color _primaryColor = Color(0xFF2E7D32); // Modern Emerald Green
const Color _darkText = Color(0xFF1E293B);

enum _ScanStep { capture, analysis, result }

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
// the recommendation below is derived from the resulting class.
class _ScanOutcome {
  const _ScanOutcome({
    required this.label,
    required this.confidence,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.symptom,
    required this.recommendation,
  });

  final String label;
  final double confidence;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String symptom;
  final _Recommendation recommendation;
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
  ),
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  _ScanStep _step = _ScanStep.capture;
  File? _image;
  _ScanOutcome? _outcome;
  bool _isPicking = false; // Guards against double-taps re-entering the picker.

  // Lets the user choose whether to take a new photo or upload an existing one.
  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
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
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: _primaryColor,
              ),
              title: const Text('Upload from Gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _image = File(picked.path));
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isCamera = source == ImageSource.camera;
      final message = e.code == 'camera_access_denied'
          ? 'Camera access denied. Enable it in your device settings.'
          : e.code == 'photo_access_denied'
          ? 'Photo library access denied. Enable it in your device settings.'
          : 'Could not open the ${isCamera ? 'camera' : 'gallery'}. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _isPicking = false;
    }
  }

  // TODO: swap this simulated delay + random pick for a real on-device or
  // API-based nutrient-deficiency detection model.
  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _step = _ScanStep.analysis);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _outcome = _mockOutcomes[Random().nextInt(_mockOutcomes.length)];
      _step = _ScanStep.result;
    });
  }

  void _reset() {
    setState(() {
      _step = _ScanStep.capture;
      _image = null;
      _outcome = null;
    });
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
              _ScanStep.analysis => _buildAnalysisStep(),
              _ScanStep.result => _buildResultStep(),
            },
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),

      // --- Centre Scan Button ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AppScanButton(
        onPressed: () {
          if (_step == _ScanStep.capture) {
            _showImageSourceSheet();
          } else {
            _reset();
          }
        },
      ),

      bottomNavigationBar: const AppBottomNav(current: AppTab.none),
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
            height: 260,
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
                      Image.file(_image!, fit: BoxFit.cover),
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
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTipCard(
                title: 'Best Practices',
                icon: Icons.check_circle_rounded,
                color: _primaryColor,
                tips: const [
                  'Take photo in good light',
                  'Focus on middle leaves',
                  'Fill frame with leaf',
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTipCard(
                title: 'Avoid',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFE65100),
                tips: const [
                  'Blurry or out-of-focus',
                  'Dark shadows or rain',
                  'Far away shots',
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Supported Classes',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDetectChip('N Nitrogen', _primaryColor),
            _buildDetectChip('P Phosphorus', const Color(0xFF0284C7)),
            _buildDetectChip('K Potassium', const Color(0xFFE65100)),
            _buildDetectChip('Healthy Leaf', _primaryColor),
          ],
        ),
        const SizedBox(height: 24),
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
                borderRadius: BorderRadius.circular(16),
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

  // --- Step 2: Analysis ---
  Widget _buildAnalysisStep() {
    return SizedBox(
      height: 380,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                _image!,
                height: 160,
                width: 160,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 28),
          const CircularProgressIndicator(color: _primaryColor, strokeWidth: 3),
          const SizedBox(height: 20),
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
            'Matching the leaf against known deficiency classes',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Result ---
  Widget _buildResultStep() {
    final outcome = _outcome!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              _image!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 20),
        Container(
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
                style: const TextStyle(
                  fontSize: 13,
                  color: _darkText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- System-generated fertilizer recommendation ---
        _buildRecommendationCard(outcome),
        const SizedBox(height: 24),
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
      ],
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
          _buildRecommendationRow(
            Icons.straighten_rounded,
            'Rate',
            rec.rate,
          ),
          _buildRecommendationRow(
            Icons.schedule_rounded,
            'Timing',
            rec.timing,
          ),
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

  Widget _buildTipCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> tips,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $tip',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
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
