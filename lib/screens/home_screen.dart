import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/confidence.dart';
import '../core/no_transition_route.dart';
import '../core/throttled_loader.dart';
import '../models/scan_result.dart';
import '../services/detection_service.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/list_group.dart';
import '../widgets/nutrient_dot.dart';
import '../widgets/page_heading.dart';
import '../widgets/scan_photo.dart';
import 'deficiency_alerts_screen.dart';
import 'fertilizer_recommendations_screen.dart';
import 'nutrient_guide_screen.dart';
import 'scan_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onScan});

  // Switches the tab shell to the Scan tab.
  final VoidCallback? onScan;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Home greets every signed-in user as "Farmer" rather than their real name.
  static const String _displayName = 'Farmer';

  // How many recent scans the NPK summary covers.
  static const int _summaryWindow = 12;
  static const List<String> _summaryLabels = [
    'Nitrogen Deficiency',
    'Phosphorus Deficiency',
    'Potassium Deficiency',
    'Healthy',
  ];
  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday',
  ];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  List<ScanResult> _scans = [];

  // Guards against repeated pull-to-refresh firing a request each time.
  late final ThrottledLoader _loader = ThrottledLoader(_loadDashboard);

  @override
  void initState() {
    super.initState();
    ScanService.changes.addListener(_onScansChanged);
    _loader();
  }

  @override
  void dispose() {
    ScanService.changes.removeListener(_onScansChanged);
    super.dispose();
  }

  void _onScansChanged() => _loader(force: true);

  Future<void> _loadDashboard() async {
    final scans = await const ScanService().getHistory();
    if (!mounted) return;
    setState(() => _scans = scans);
  }

  // Scan count per summary label, using each scan's representative result.
  Map<String, int> get _summaryCounts {
    final counts = {for (final label in _summaryLabels) label: 0};
    for (final scan in _scans.take(_summaryWindow)) {
      final label = scan.primaryDetection.label;
      if (counts.containsKey(label)) counts[label] = counts[label]! + 1;
    }
    return counts;
  }

  int get _alertCount => [
    for (final scan in _scans) ...scan.detections.where((d) => !d.isHealthy),
  ].length;

  String get _today {
    final now = DateTime.now();
    return '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${_months[date.month - 1].substring(0, 3)} ${date.day}';
  }

  void _open(Widget page) {
    Navigator.push(context, noTransitionRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loader.call,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + AppTopBar.height + 8,
            20,
            32,
          ),
          children: [
            Text(
              _today,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Welcome, $_displayName',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.1,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 18),
            _scans.isEmpty ? _buildFirstScanCard() : _buildLatestCard(),
            if (_scans.isNotEmpty) ...[
              SectionTitle(
                'Last ${_scans.length.clamp(1, _summaryWindow)} scans',
                action: 'View history',
                onAction: () => _open(const ScanHistoryScreen()),
              ),
              _buildSummaryCard(),
            ],
            const SectionTitle('Tools'),
            _buildToolsList(),
          ],
        ),
      ),
    );
  }

  // Dark hero card with the most recent scan and its top result.
  Widget _buildLatestCard() {
    final scan = _scans.first;
    final detection = scan.primaryDetection;
    final extra = scan.detections.length - 1;
    final confidence = detection.confidence.clamp(0.0, 1.0).toDouble();

    return Material(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(ScanHistoryDetailScreen(scan: scan)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 96,
                  height: 118,
                  child: ScanPhoto(key: ValueKey(scan.id), scan: scan),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LATEST SCAN \u00B7 ${_timeAgo(scan.createdAt).toUpperCase()}'
                      '${DetectionService.isSample ? ' \u00B7 SAMPLE' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9FC3A8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detection.isHealthy ? 'Healthy leaf' : detection.label,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    if (extra > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+$extra more ${extra == 1 ? 'area' : 'areas'} found',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCFE2D4),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        NutrientDot(label: detection.label),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            confidenceWord(confidence),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCFE2D4),
                            ),
                          ),
                        ),
                        Text(
                          confidencePercent(confidence),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: confidence,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.corn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detection.isHealthy
                          ? 'View scan details \u2192'
                          : 'See what to apply \u2192',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.corn,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shown before any scan exists: explains the app and points to Scan.
  Widget _buildFirstScanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              NutrientDot(label: 'Nitrogen'),
              SizedBox(width: 4),
              NutrientDot(label: 'Phosphorus'),
              SizedBox(width: 4),
              NutrientDot(label: 'Potassium'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Scan your first leaf',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Take a clear photo of one corn leaf to check it for nitrogen, '
            'phosphorus or potassium deficiency.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFFCFE2D4),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onScan,
            icon: const Icon(Icons.photo_camera_outlined, size: 20),
            label: const Text('Scan a leaf'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.corn,
              foregroundColor: AppColors.textDark,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stacked NPK bar plus one count column per result type.
  Widget _buildSummaryCard() {
    final counts = _summaryCounts;
    final nonZero = _summaryLabels.where((l) => counts[l]! > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              // Stretch so the childless ColoredBox segments fill the height.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < nonZero.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: counts[nonZero[i]]!,
                      child: ColoredBox(
                        color: AppColors.nutrient(nonZero[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < _summaryLabels.length; i++) ...[
                  if (i > 0)
                    const VerticalDivider(
                      width: 20,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                  Expanded(
                    child: _buildSummaryColumn(
                      _summaryLabels[i],
                      counts[_summaryLabels[i]]!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NutrientDot(label: label, size: 28),
        const SizedBox(height: 10),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.replaceAll(' Deficiency', ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildToolsList() {
    final alerts = _alertCount;
    return ListGroup(
      children: [
        ListRow(
          icon: Icons.warning_amber_rounded,
          title: 'Deficiency alerts',
          subtitle: 'Leaves that need attention',
          trailing: alerts > 0 ? _buildBadge('$alerts') : null,
          onTap: () => _open(const DeficiencyAlertsScreen()),
        ),
        ListRow(
          icon: Icons.menu_book_outlined,
          title: 'Nutrient guide',
          subtitle: 'Symptoms of N, P and K deficiency',
          onTap: () => _open(const NutrientGuideScreen()),
        ),
        ListRow(
          icon: Icons.science_outlined,
          title: 'Fertilizer guide',
          subtitle: 'Recommended rates and timing',
          onTap: () => _open(const FertilizerRecommendationsScreen()),
        ),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.phosphorus,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  static final BoxDecoration _cardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.border),
  );
}
