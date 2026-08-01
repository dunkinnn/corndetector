import 'package:flutter/material.dart';

import '../core/no_transition_route.dart';
import '../widgets/app_top_bar.dart';
import 'monitoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0; // 0: Home, 1: Scan (Center), 2: Monitoring

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF388E3C); // Agriculture Green

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(),

      // --- Main Body ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height:
                  MediaQuery.of(context).padding.top + AppTopBar.height + 16,
            ),
            // --- Welcome Header ---
            const Text(
              'Welcome, FarmerJD',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Field Monitor & Crop Diagnostics',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // --- Weather & Field Condition Bar ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherMetric(
                    Icons.wb_sunny_outlined,
                    '31°C',
                    'Weather',
                  ),
                  _buildDivider(),
                  _buildWeatherMetric(
                    Icons.water_drop_outlined,
                    '68%',
                    'Humidity',
                  ),
                  _buildDivider(),
                  _buildWeatherMetric(
                    Icons.grass_outlined,
                    'Optimal',
                    'Soil Moisture',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Crop Health Overview ---
            const Text(
              'Crop Health Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHealthCard(
                    title: 'Healthy Crop',
                    value: '85%',
                    color: primaryColor,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthCard(
                    title: 'Needs Attention',
                    value: '15%',
                    color: const Color(0xFFE65100),
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Quick Actions Header ---
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // --- Action Cards ---
            _buildActionCard(
              icon: Icons.bug_report_outlined,
              title: 'Pest & Deficiency Alerts',
              subtitle: 'Check potential risks for current season',
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.menu_book_outlined,
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
        height: 80,
        width: 80,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(6), // Light outer border ring
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: () => setState(() => _selectedTab = 1),
          backgroundColor: primaryColor,
          elevation: 2,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.camera_alt_rounded,
            size: 34, // Increased FAB icon size
            color: Colors.white,
          ),
        ),
      ),

      // --- Bottom Navigation Bar with Larger Icons & Text ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, -4),
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
              height: 76, // A bit of headroom so the 32px icon + 14px label don't overflow
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

  // Weather Metric Component
  Widget _buildWeatherMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 24, width: 1, color: Colors.black12);
  }

  // Health Card Component
  Widget _buildHealthCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Navigation Item with Larger Icon (32px) and Larger Label (14px)
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        // Scales the icon+label down instead of overflowing if the available
        // height ever ends up a few pixels short (varies with font metrics).
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 32, // Increased from 26
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14, // Increased from 12
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

  // Quick Action Card Template
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF388E3C), size: 22),
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
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
