import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFF9FAFB),

      // --- Top Header with Actual PNG Logo ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            // Render actual PNG logo asset
            Image.asset(
              'assets/images/logo.png',
              height:
                  36, // Adjust height as needed for your logo's aspect ratio
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if asset path isn't found in pubspec.yaml
                return const Icon(Icons.eco, color: primaryColor, size: 32);
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'MaisNutri',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),

      // --- Main Body ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            const SizedBox(height: 80), // Space to avoid bottom bar overlap
          ],
        ),
      ),

      // --- Floating Center Action Button (Scan) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 24),
        child: FloatingActionButton(
          onPressed: () => setState(() => _selectedTab = 1),
          backgroundColor: primaryColor,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),

      // --- Modern Bottom Navigation Bar ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
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
              const SizedBox(width: 48),

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

  // Bottom Navigation Bar Item Builder
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color primaryColor,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryColor : Colors.black38,
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? primaryColor : Colors.black45,
            ),
          ),
        ],
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
