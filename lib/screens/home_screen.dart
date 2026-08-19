import 'package:flutter/material.dart';

import '../core/no_transition_route.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import 'deficiency_alerts_screen.dart';
import 'fertilizer_recommendations_screen.dart';
import 'nutrient_guide_screen.dart';
import 'scan_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Shown wherever a metric has no real data source yet.
const String _placeholder = '--';

class _HomeScreenState extends State<HomeScreen> {
  // Home greets every signed-in user as "Farmer" rather than their real name.
  static const String _displayName = 'Farmer';
  List<ScanResult> _scans = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final scans = await const ScanService().getHistory();
    if (!mounted) return;
    setState(() {
      _scans = scans;
    });
  }

  // Most recent scan's representative result (worst-case detection if the
  // scan found more than one region - see ScanResult.primaryDetection).
  // "+N" is appended when there were other detections in that same scan.
  String get _latestResult {
    if (_scans.isEmpty) return _placeholder;
    final scan = _scans.first;
    final label = scan.primaryDetection.label;
    final extra = scan.detections.length - 1;
    return extra > 0 ? '$label +$extra' : label;
  }

  String get _latestConfidence => _scans.isEmpty
      ? _placeholder
      : '${(_scans.first.primaryDetection.confidence * 100).round()}%';
  String get _latestScanDate =>
      _scans.isEmpty ? _placeholder : _formatDate(_scans.first.createdAt);

  int get _healthyCount => _scans.where((s) => s.isHealthy).length;
  int get _deficientCount => _scans.where((s) => !s.isHealthy).length;

  int get _totalScans => _healthyCount + _deficientCount;
  bool get _hasScans => _totalScans > 0;

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  // Opens a quick action sub-screen on top of Home.
  void _open(Widget page) {
    Navigator.push(context, noTransitionRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32); // Modern Emerald Green
    const accentColor = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8), // Soft off-white background
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(),

      // --- Main Body ---
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height:
                  MediaQuery.of(context).padding.top + AppTopBar.height + 16,
            ),

            // --- Welcome Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Latest Detection Card ---
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [primaryColor, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Latest Detection',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Most Recent',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetectionMetric(
                                Icons.grass_rounded,
                                _latestResult,
                                'Result',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDetectionMetric(
                                Icons.percent_rounded,
                                _latestConfidence,
                                'Confidence',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDetectionMetric(
                                Icons.schedule_rounded,
                                _latestScanDate,
                                'Last Scan',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --- Empty State ---
            // Explains the placeholders before any scan has been recorded.
            if (!_hasScans) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No scans yet. Tap the camera button to scan a corn leaf.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // --- Scan Summary Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _hasScans ? '$_totalScans total' : '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Scan Summary Cards ---
            // Plain counts of past scans, so no aggregation rule is implied.
            Row(
              children: [
                Expanded(
                  child: _buildHealthCard(
                    title: 'Healthy Scans',
                    value: _hasScans ? '$_healthyCount' : _placeholder,
                    color: primaryColor,
                    progress: _hasScans ? _healthyCount / _totalScans : 0,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildHealthCard(
                    title: 'Deficient Scans',
                    value: _hasScans ? '$_deficientCount' : _placeholder,
                    color: const Color(0xFFE65100),
                    progress: _hasScans ? _deficientCount / _totalScans : 0,
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- Quick Actions Header ---
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),

            // --- Action Cards ---
            _buildActionCard(
              icon: Icons.warning_amber_rounded,
              title: 'Deficiency Alerts',
              subtitle: 'Review detected N, P, K deficiencies',
              onTap: () => _open(const DeficiencyAlertsScreen()),
            ),
            _buildActionCard(
              icon: Icons.menu_book_rounded,
              title: 'Nutrient Guide',
              subtitle: 'Symptoms and causes of each deficiency',
              onTap: () => _open(const NutrientGuideScreen()),
            ),
            _buildActionCard(
              icon: Icons.science_rounded,
              title: 'Fertilizer Recommendations',
              subtitle: 'Suggested dosage and application timing',
              onTap: () => _open(const FertilizerRecommendationsScreen()),
            ),
            _buildActionCard(
              icon: Icons.history_rounded,
              title: 'Scan History',
              subtitle: 'Past leaf scans and deficiency results',
              onTap: () => _open(const ScanHistoryScreen()),
            ),

            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),

      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
    );
  }

  // Detection Metric Component for the latest detection card.
  Widget _buildDetectionMetric(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Health Card Component with Visual Progress Indicator
  Widget _buildHealthCard({
    required String title,
    required String value,
    required Color color,
    required double progress,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Action Card Template
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade100),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
