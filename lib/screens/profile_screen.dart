import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/no_transition_route.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'help_about_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _primaryColor = Color(0xFF2E7D32);
  static const _bgCanvas = Color(0xFFF8FAF8); // Matches the other screens
  static const _textMain = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.of(context).padding.top + AppTopBar.height + 20;

    return Scaffold(
      backgroundColor: _bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Profile',
        description: 'Account settings and preferences',
        showProfile: false,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(20.0, topPadding, 20.0, 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- User Info Strip ---
            _buildUserHeader(context),

            const SizedBox(height: 20),

            // --- Section: Account Settings ---
            _buildSectionHeader('ACCOUNT'),
            _buildGroupContainer(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  subtitle: 'Your name and email',
                  onTap: () => _open(context, const EditProfileScreen()),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Notifications and scanning',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Section: Support & Legal ---
            _buildSectionHeader('SUPPORT & INFO'),
            _buildGroupContainer(
              children: [
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & About',
                  subtitle: 'How to scan, app info and disclaimer',
                  onTap: () => _open(context, const HelpAboutScreen()),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'App Version',
                  subtitle: '${AppInfo.name} v${AppInfo.version}',
                  showChevron: false,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Section: Session Management ---
            _buildGroupContainer(
              children: [
                _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  titleColor: const Color(0xFFDC2626),
                  iconColor: const Color(0xFFDC2626),
                  iconBgColor: const Color(0xFFFEF2F2),
                  showChevron: false,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ],
        ),
      ),

      // --- Bottom Navigation Integration ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AppScanButton(
        onPressed: () =>
            Navigator.push(context, noTransitionRoute(const ScanScreen())),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
    );
  }

  // --- User Header Strip ---
  // TODO: read the name and email from the signed in account.
  Widget _buildUserHeader(BuildContext context) {
    const displayName = 'Farmers';
    const email = '';
    final initial = displayName.isEmpty
        ? '?'
        : displayName.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _primaryColor.withValues(alpha: 0.1),
            child: Text(
              initial,
              style: const TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isEmpty ? 'Add your email' : email,
                  style: TextStyle(
                    fontSize: 13,
                    color: email.isEmpty ? _primaryColor : _textMuted,
                    fontWeight: email.isEmpty
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _open(context, const EditProfileScreen()),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shared card look, matching the cards on Home and the sub-screens.
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // --- Grouped Settings Container ---
  // Clips so tile ink splashes stay inside the rounded corners.
  Widget _buildGroupContainer({required List<Widget> children}) {
    return Container(
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  // --- Clean List Tile Item ---
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = _textMain,
    Color iconColor = _primaryColor,
    Color? iconBgColor,
    bool showChevron = true,
    // Null makes the row informational, with no ripple and no tap target.
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor ?? _primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Indent lines the rule up with the tile text, past the icon.
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 62,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, noTransitionRoute(page));
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold, color: _textMain),
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              dialogContext,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
