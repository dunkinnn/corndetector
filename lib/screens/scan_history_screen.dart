import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../core/colors.dart';
import '../core/confidence.dart';
import '../models/scan_result.dart';
import '../services/detection_service.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/nutrient_dot.dart';
import '../widgets/scan_photo.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  static const Color _primaryColor = AppColors.primary;
  static const Color _bgCanvas = AppColors.background;
  static const Color _textMuted = AppColors.textMuted;

  late final Future<List<ScanResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = const ScanService().getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Scan History',
        description: 'Past leaf scans and their results',
        showProfile: false,
        showBack: true,
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
            FutureBuilder<List<ScanResult>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    ),
                  );
                }
                final scans = snapshot.data ?? [];
                if (scans.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No scans recorded',
                    message:
                        'Every leaf you scan will be listed here with its result '
                        'and the date it was taken.',
                  );
                }
                return Column(children: scans.map(_buildScanCard).toList());
              },
            ),
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),
    );
  }

  // One row per scan: NPK dot for its top result, every detection's label
  // and confidence, and the scan date.
  Widget _buildScanCard(ScanResult scan) {
    final primary = scan.primaryDetection;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScanHistoryDetailScreen(scan: scan),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                NutrientDot(label: primary.label, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final d in scan.detections)
                        Text(
                          '${d.isHealthy ? 'Healthy' : d.label} '
                          '\u00B7 ${confidencePercent(d.confidence)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(scan.createdAt),
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

// Result view for one scan: photo with NPK boxes, then a sheet per detection.
class ScanHistoryDetailScreen extends StatefulWidget {
  const ScanHistoryDetailScreen({super.key, required this.scan});

  final ScanResult scan;

  @override
  State<ScanHistoryDetailScreen> createState() =>
      _ScanHistoryDetailScreenState();
}

class _ScanHistoryDetailScreenState extends State<ScanHistoryDetailScreen> {
  // Until the photo's shape is known, and bounds for very tall photos.
  static const double _minPhotoHeight = 280;
  static const double _maxPhotoHeightFraction = 0.72;

  // Photo width divided by height, reported by ScanPhoto once it loads.
  double? _aspect;
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  ScanResult get scan => widget.scan;

  String get _dateTime {
    final d = scan.createdAt.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${_months[d.month - 1]} ${d.day}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    // The photo fills the width and the status bar area; its height follows
    // its own shape, so there are no bars beside it.
    final aspect = _aspect;
    final photoHeight = aspect == null
        ? _minPhotoHeight
        : (media.size.width / aspect).clamp(
            _minPhotoHeight,
            media.size.height * _maxPhotoHeightFraction - top,
          );
    final primary = scan.primaryDetection;
    final areas = scan.detections.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Stack(
          children: [
            // The status bar gets its own dark strip, so the phone's clock
            // and icons never sit on top of the photo.
            Column(
              children: [
                Container(height: top, color: AppColors.primaryDark),
                SizedBox(
                  height: photoHeight,
                  width: double.infinity,
                  child: ScanPhoto(
                    scan: scan,
                    showLabels: true,
                    fitWhole: true,
                    onAspect: (value) => setState(() => _aspect = value),
                  ),
                ),
              ],
            ),
            Positioned(
              top: top + 8,
              left: 16,
              child: CircleBackButton(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                showBorder: false,
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: top + photoHeight - 26),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NutrientTag(label: primary.label),
                  const SizedBox(height: 10),
                  Text(
                    primary.isHealthy ? 'Healthy leaf' : primary.label,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1.05,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${confidenceWord(primary.confidence)} '
                    '(${confidencePercent(primary.confidence)}) '
                    '\u00B7 $areas ${areas == 1 ? 'area' : 'areas'} found '
                    '\u00B7 $_dateTime',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (DetectionService.isSample) const _SampleNotice(),
                  if (scan.detections.any(
                    (d) => confidenceLevel(d.confidence) == ConfidenceLevel.low,
                  ))
                    const _LowConfidenceNotice(),
                  for (final detection in scan.detections) ...[
                    if (areas > 1) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          NutrientDot(label: detection.label),
                          const SizedBox(width: 8),
                          Text(
                            '${detection.label} \u00B7 '
                            '${confidencePercent(detection.confidence)}',
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                    _DetectionDetails(detection: detection),
                  ],
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

// Warns that a low-scoring result should not be acted on as-is.
class _LowConfidenceNotice extends StatelessWidget {
  const _LowConfidenceNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.corn.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textDark),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'The model is unsure about this leaf. Retake the photo in good '
              'light, filling the frame with one leaf, before applying any '
              'fertilizer.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Explains that results are simulated until the trained model is added.
class _SampleNotice extends StatelessWidget {
  const _SampleNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.corn.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textDark),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sample result. The detection model is not trained yet, so '
              'this is not a real diagnosis.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Colored dot plus nutrient name, e.g. "N  Nitrogen".
class _NutrientTag extends StatelessWidget {
  const _NutrientTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NutrientDot(label: label),
        const SizedBox(width: 6),
        Text(
          label.replaceAll(' Deficiency', ''),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.nutrient(label),
          ),
        ),
      ],
    );
  }
}

// "What we see" and "Recommendations" cards for one detection.
class _DetectionDetails extends StatelessWidget {
  const _DetectionDetails({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(
          heading: 'What we see',
          child: Text(detection.symptom, style: _bodyStyle),
        ),
        _InfoCard(
          heading: 'Recommendations',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detection.fertilizer,
                style: _bodyStyle.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Fact(value: detection.rate, label: 'Rate')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Fact(value: detection.timing, label: 'Timing'),
                  ),
                ],
              ),
              if (detection.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  detection.note,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppColors.textDark,
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.heading, required this.child});

  final String heading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// Small value-over-label tile inside the "Recommendations" card.
class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
