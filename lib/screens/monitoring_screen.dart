import 'package:flutter/material.dart';

import '../core/no_transition_route.dart';
import '../widgets/app_top_bar.dart';
import 'home_screen.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  int _selectedTab = 2; // Selected index for Monitoring tab

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF388E3C); // Agriculture Green

    return Scaffold(
      backgroundColor: Colors.white,
      // Body draws behind the frosted-glass header so the blur has content
      // scrolling under it to blur.
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Monitoring',
        description: 'Track your corn crop health and nutrient status',
        showProfile: false,
      ),

      // --- Main Body ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height:
                  MediaQuery.of(context).padding.top + AppTopBar.height + 20,
            ),

            // --- Modern Summary Statistics Row ---
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    value: '15',
                    label: 'Total Scans',
                    color: Colors.blue.shade700,
                    icon: Icons.qr_code_scanner,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    value: '80%',
                    label: 'Healthy Crops',
                    color: primaryColor,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    value: '3',
                    label: 'Needs Attention',
                    color: const Color(0xFFE65100),
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Section Title ---
            const Text(
              'Recent Detections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // --- Detection List ---
            _buildDetectionCard(
              title: 'Nitrogen Deficiency',
              timestamp: 'Oct 24, 2023 • 2 hours ago',
              badgeLabel: 'Deficient',
              badgeColor: const Color(0xFFD32F2F),
              badgeBgColor: const Color(0xFFFFEBEE),
              icon: Icons.grass,
            ),
            _buildDetectionCard(
              title: 'Healthy Crop',
              timestamp: 'Oct 22, 2023 • 5 hours ago',
              badgeLabel: 'Healthy',
              badgeColor: primaryColor,
              badgeBgColor: const Color(0xFFE8F5E9),
              icon: Icons.check_circle,
            ),
            _buildDetectionCard(
              title: 'Phosphorus Deficiency',
              timestamp: 'Oct 21, 2023 • 1 day ago',
              badgeLabel: 'Deficient',
              badgeColor: const Color(0xFFD32F2F),
              badgeBgColor: const Color(0xFFFFEBEE),
              icon: Icons.grass,
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
                    onTap: () => Navigator.pushReplacement(
                      context,
                      noTransitionRoute(const HomeScreen()),
                    ),
                  ),

                  // Spacer for the center Scan FloatingActionButton
                  const SizedBox(width: 64),

                  // Right Tab: Monitoring
                  _buildNavItem(
                    icon: Icons.insights_rounded,
                    label: 'Monitoring',
                    index: 2,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Stat Card Builder ---
  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // --- Detection Card Builder ---
  Widget _buildDetectionCard({
    required String title,
    required String timestamp,
    required String badgeLabel,
    required Color badgeColor,
    required Color badgeBgColor,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: badgeColor, size: 22),
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
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
}
