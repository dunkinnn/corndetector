import 'package:flutter/material.dart';

import '../widgets/app_top_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _darkText = Color(0xFF1E293B);

  // TODO: persist with shared_preferences, as the login screen already does.
  bool _scanReminders = true;
  bool _deficiencyAlerts = true;
  bool _saveScanPhotos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Settings',
        description: 'Notifications and app preferences',
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

            _buildSectionTitle('Notifications'),
            _buildSwitchTile(
              icon: Icons.notifications_none_rounded,
              title: 'Scan Reminders',
              subtitle: 'Remind me to scan my crop regularly',
              value: _scanReminders,
              onChanged: (v) => setState(() => _scanReminders = v),
            ),
            _buildSwitchTile(
              icon: Icons.warning_amber_rounded,
              title: 'Deficiency Alerts',
              subtitle: 'Notify me when a deficiency is detected',
              value: _deficiencyAlerts,
              onChanged: (v) => setState(() => _deficiencyAlerts = v),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Scanning'),
            _buildSwitchTile(
              icon: Icons.photo_library_outlined,
              title: 'Save Scan Photos',
              subtitle: 'Keep a copy of every leaf photo on this device',
              value: _saveScanPhotos,
              onChanged: (v) => setState(() => _saveScanPhotos = v),
            ),

            const SizedBox(height: 20),
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
                    'These preferences are not saved yet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _darkText,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // Settings row with a trailing switch, styled like the profile tiles.
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                color: _primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _primaryColor, size: 22),
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
                      color: _darkText,
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
            // Colour comes from the app theme, which is seeded with the brand
            // green, so no explicit override is needed here.
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
