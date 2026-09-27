import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/colors.dart';
import '../core/no_transition_route.dart';
import '../core/throttled_loader.dart';
import '../models/scan_result.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/list_group.dart';
import '../widgets/page_heading.dart';
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
  UserProfile? _profile;
  List<ScanResult> _scans = [];

  // Guards against repeated pull-to-refresh firing a request each time.
  late final ThrottledLoader _loader = ThrottledLoader(
    () => Future.wait([_loadProfile(), _loadScans()]),
  );

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

  Future<void> _loadProfile() async {
    final profile = await const ProfileService().getCurrentProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _loadScans() async {
    final scans = await const ScanService().getHistory();
    if (mounted) setState(() => _scans = scans);
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
            const PageHeading(kicker: 'Your account', title: 'Profile'),
            _buildHeroCard(),
            const SectionTitle('Account'),
            ListGroup(
              children: [
                ListRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit profile',
                  subtitle: 'Your display name and email',
                  onTap: _openEditProfile,
                ),
                ListRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  subtitle: 'Update your account password',
                  onTap: () => _open(context, const ChangePasswordScreen()),
                ),
                ListRow(
                  icon: Icons.tune_rounded,
                  title: 'Settings',
                  subtitle: 'Notifications and scanning',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
              ],
            ),
            const SectionTitle('Support'),
            ListGroup(
              children: [
                ListRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & about',
                  subtitle: 'How to scan, app info and disclaimer',
                  onTap: () => _open(context, const HelpAboutScreen()),
                ),
                const ListRow(
                  icon: Icons.info_outline_rounded,
                  title: 'App version',
                  trailing: Text(
                    '${AppInfo.name} ${AppInfo.version}',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListGroup(
              children: [
                ListRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  color: AppColors.errorRed,
                  trailing: const SizedBox.shrink(),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    await _open(context, const EditProfileScreen());
    _loadProfile();
  }

  // Dark card with avatar, name, email and the user's scan totals.
  Widget _buildHeroCard() {
    final name = _profile?.fullName.trim() ?? '';
    final displayName = name.isEmpty ? 'Farmer' : name;
    final email = _profile?.email.trim() ?? '';
    final deficient = _scans.where((s) => !s.isHealthy).length;

    return Material(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openEditProfile,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.corn,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email.isEmpty ? 'Add your email' : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: email.isEmpty
                                ? AppColors.corn
                                : const Color(0xFFCFE2D4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF9FC3A8),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildStat('${_scans.length}', 'Scans'),
                  _buildStat('$deficient', 'Deficient'),
                  _buildStat('${_scans.length - deficient}', 'Healthy'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9FC3A8)),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) {
    return Navigator.push(context, noTransitionRoute(page));
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Sign out?',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            fontSize: 22,
          ),
        ),
        content: const Text(
          'You will need to log back in to see your scans.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, top: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Close the confirmation modal.
              _performSignOut(context);
            },
            child: const Text(
              'Sign out',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // Shows a bare spinner (no dialog card/modal chrome around it) while
  // signing out, then swaps to Login. Kept separate from the confirmation
  // modal above so the loading state isn't shown inside that dialog.
  Future<void> _performSignOut(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // No barrierColor override - same default dim (Colors.black54) as the
      // confirmation modal above, so the backdrop looks consistent between
      // the two instead of going lighter for the spinner.
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: AppColors.corn)),
    );
    // Supabase's signOut() often resolves in a few ms, which can pop the
    // spinner before its push animation even finishes - so it never reads
    // as "loading," just a flicker. Wait for whichever takes longer so it
    // always shows for a beat.
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 500));
    try {
      await Future.wait([const AuthService().signOut(), minDelay]);
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss spinner.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign out. Try again.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Dismiss spinner.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
