import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/no_transition_route.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import 'auth/login_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_about_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Brand Color Palette
  static const _primaryColor = Color(0xFF2E7D32);
  static const _primaryLight = Color(0xFFE8F5E9);
  static const _bgCanvas = Color(0xFFF8FAF8);
  static const _cardBg = Colors.white;
  static const _textMain = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);
  static const _dangerColor = Color(0xFFEF4444);
  static const _dangerBg = Color(0xFFFEF2F2);

  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await const ProfileService().getCurrentProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.of(context).padding.top + AppTopBar.height + 16;

    return Scaffold(
      backgroundColor: _bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Profile',
        description: 'Account settings & preferences',
        showProfile: false,
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(20.0, topPadding, 20.0, 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Dynamic Profile Hero Card (Without Edit Icon) ---
              _buildModernUserHeader(context),

              const SizedBox(height: 28),

              // --- Section: Account Settings ---
              _buildSectionHeader('ACCOUNT MANAGEMENT'),
              _buildGroupContainer(
                children: [
                  _buildSettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your display name and email',
                    onTap: () async {
                      await _open(context, const EditProfileScreen());
                      _loadProfile();
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => _open(context, const ChangePasswordScreen()),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: Icons.tune_rounded,
                    title: 'App Settings',
                    subtitle: 'Manage notifications and scanner preferences',
                    onTap: () => _open(context, const SettingsScreen()),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Section: Support & Info ---
              _buildSectionHeader('SUPPORT & INFORMATION'),
              _buildGroupContainer(
                children: [
                  _buildSettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'Scanning guides, app info, and disclaimers',
                    onTap: () => _open(context, const HelpAboutScreen()),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: Icons.verified_outlined,
                    title: 'App Version',
                    subtitle: '${AppInfo.name} v${AppInfo.version}',
                    showChevron: false,
                    badgeText: 'Latest',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Section: Session Management ---
              _buildGroupContainer(
                children: [
                  _buildSettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Safely log out of your current session',
                    titleColor: _dangerColor,
                    iconColor: _dangerColor,
                    iconBgColor: _dangerBg,
                    showChevron: false,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
    );
  }

  // Modern Hero Header Widget
  Widget _buildModernUserHeader(BuildContext context) {
    final displayName = (_profile?.fullName.trim().isNotEmpty ?? false)
        ? _profile!.fullName.trim()
        : 'Farmer';
    final email = (_profile?.email.trim().isNotEmpty ?? false)
        ? _profile!.email.trim()
        : '';
    final initial = displayName.isEmpty
        ? '?'
        : displayName.substring(0, 1).toUpperCase();

    return Container(
      width: double.infinity,
      decoration: _modernCardDecoration(),
      child: Stack(
        children: [
          // Background Gradient Pattern Accent
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: _primaryColor.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Badge Overlay
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primaryColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: _primaryLight,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: _primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: _textMain,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.isEmpty ? 'Add your email' : email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: email.isEmpty ? _primaryColor : _textMuted,
                          fontWeight: email.isEmpty
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Group Container with smooth clipping and premium styling
  Widget _buildGroupContainer({required List<Widget> children}) {
    return Container(
      decoration: _modernCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: children),
      ),
    );
  }

  // Modernized Settings Tile Widget
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = _textMain,
    Color iconColor = _primaryColor,
    Color? iconBgColor,
    bool showChevron = true,
    String? badgeText,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor ?? _primaryLight,
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _textMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (showChevron)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _textMuted,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
  }

  BoxDecoration _modernCardDecoration() {
    return BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, Widget page) {
    return Navigator.push(context, noTransitionRoute(page));
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _textMain,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out? You will need to log back in to access your data.',
          style: TextStyle(color: _textMuted, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, top: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await const AuthService().signOut();
              if (!dialogContext.mounted) return;
              Navigator.pushAndRemoveUntil(
                dialogContext,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: _dangerColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
