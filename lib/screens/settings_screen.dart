import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/list_group.dart';
import '../widgets/page_heading.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _scanReminders = true;
  bool _deficiencyAlerts = true;
  bool _saveScanPhotos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(showProfile: false, showBack: true),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + AppTopBar.height + 8,
          20,
          32,
        ),
        children: [
          const PageHeading(kicker: 'Preferences', title: 'Settings'),
          const SectionTitle('Notifications'),
          ListGroup(
            children: [
              ListRow(
                icon: Icons.notifications_none_rounded,
                title: 'Scan reminders',
                subtitle: 'Remind me to scan my crop regularly',
                trailing: _buildSwitch(
                  _scanReminders,
                  (v) => setState(() => _scanReminders = v),
                ),
              ),
              ListRow(
                icon: Icons.warning_amber_rounded,
                title: 'Deficiency alerts',
                subtitle: 'Notify me when a deficiency is detected',
                trailing: _buildSwitch(
                  _deficiencyAlerts,
                  (v) => setState(() => _deficiencyAlerts = v),
                ),
              ),
            ],
          ),
          const SectionTitle('Scanning'),
          ListGroup(
            children: [
              ListRow(
                icon: Icons.photo_library_outlined,
                title: 'Save scan photos',
                subtitle: 'Keep a copy of every leaf photo on this device',
                trailing: _buildSwitch(
                  _saveScanPhotos,
                  (v) => setState(() => _saveScanPhotos = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These preferences are not saved yet.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
      inactiveThumbColor: AppColors.textMuted,
      inactiveTrackColor: AppColors.background,
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.border),
    );
  }
}
