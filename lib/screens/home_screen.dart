import 'package:flutter/material.dart';

import '../core/no_transition_route.dart';
import '../models/field_conditions.dart';
import '../services/field_conditions_service.dart';
import '../widgets/app_top_bar.dart';
import 'monitoring_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Shown wherever a metric has no real data source yet.
const String _placeholder = '--';

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0; // 0: Home, 1: Scan (Center), 2: Monitoring

  final FieldConditionsService _conditionsService = FieldConditionsService();

  FieldConditions? _conditions;
  bool _loadingConditions = true;
  bool _conditionsFailed = false;

  @override
  void initState() {
    super.initState();
    _loadConditions();
  }

  // Pulls current conditions; leaves the card on placeholders if it fails.
  Future<void> _loadConditions() async {
    setState(() {
      _loadingConditions = true;
      _conditionsFailed = false;
    });

    try {
      final conditions = await _conditionsService.fetch();
      if (!mounted) return;
      setState(() {
        _conditions = conditions;
        _loadingConditions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingConditions = false;
        _conditionsFailed = true;
      });
    }
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
                    const Text(
                      'Farmers',
                      style: TextStyle(
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

            // --- Weather & Field Condition Card ---
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
                              'Field Live Conditions',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: _conditionsFailed ? _loadConditions : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _conditionsBadgeLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWeatherMetric(
                              Icons.wb_sunny_rounded,
                              _conditions?.temperatureLabel ?? _placeholder,
                              'Weather',
                            ),
                            _buildDivider(),
                            _buildWeatherMetric(
                              Icons.water_drop_rounded,
                              _conditions?.humidityLabel ?? _placeholder,
                              'Humidity',
                            ),
                            _buildDivider(),
                            _buildWeatherMetric(
                              Icons.grass_rounded,
                              _conditions?.soilMoistureLabel ?? _placeholder,
                              'Soil Moisture',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Crop Health Overview Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Crop Health Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Crop Health Cards ---
            Row(
              children: [
                Expanded(
                  child: _buildHealthCard(
                    title: 'Healthy Crop',
                    value: _placeholder,
                    color: primaryColor,
                    progress: 0,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildHealthCard(
                    title: 'Needs Attention',
                    value: _placeholder,
                    color: const Color(0xFFE65100),
                    progress: 0,
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
              icon: Icons.bug_report_rounded,
              title: 'Pest & Deficiency Alerts',
              subtitle: 'Check potential risks for current season',
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.menu_book_rounded,
              title: 'Nutrient & Fertilizer Guide',
              subtitle: 'Learn recommended N, P, K dosage',
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.edit_note_rounded,
              title: 'Field Notes & Logs',
              subtitle: 'Record field observations and sprays',
              onTap: () {},
            ),

            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),

      // --- Enlarged Center Action Button (Scan) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 76,
        width: 76,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () =>
              Navigator.push(context, noTransitionRoute(const ScanScreen())),
          backgroundColor: primaryColor,
          elevation: 2,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.camera_alt_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 10.0,
            clipBehavior: Clip.antiAlias,
            color: Colors.white,
            elevation: 0,
            child: SizedBox(
              height: 76,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Left Tab: Home
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    primaryColor: primaryColor,
                  ),

                  // Spacer for the center Scan FloatingActionButton
                  const SizedBox(width: 64),

                  // Right Tab: Monitoring
                  _buildNavItem(
                    icon: Icons.insights_rounded,
                    label: 'Monitoring',
                    index: 2,
                    primaryColor: primaryColor,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      noTransitionRoute(const MonitoringScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Badge doubles as the status line for the conditions fetch.
  String get _conditionsBadgeLabel {
    if (_loadingConditions) return 'Updating';
    if (_conditionsFailed) return 'Tap to retry';
    return 'Live Update';
  }

  // Modern Weather Metric Component
  Widget _buildWeatherMetric(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
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

  // Navigation Item
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color primaryColor,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedTab == index;
    final activeColor = primaryColor;
    final inactiveColor = Colors.grey.shade400;

    return InkWell(
      onTap: onTap ?? () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 32,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
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
