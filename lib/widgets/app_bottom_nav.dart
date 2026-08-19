import 'package:flutter/material.dart';

import '../core/no_transition_route.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/scan_screen.dart';

// Which peer tab is currently showing, so it can be highlighted.
enum AppTab { home, scan, profile, none }

// Bottom bar shared by every top-level screen. Home, Scan, and Profile are
// peer tabs, so they replace each other.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, this.onBeforeLeave});

  final AppTab current;

  // Called before switching tabs; return false to cancel the navigation
  // (e.g. to warn about an unsaved scan result). Defaults to always allowing.
  final Future<bool> Function()? onBeforeLeave;

  static const Color _primaryColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Container(
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
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: _buildNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: current == AppTab.home,
                      onTap: () =>
                          _goTo(context, const HomeScreen(), AppTab.home),
                    ),
                  ),
                ),
                SizedBox(
                  width: 84,
                  child: Center(
                    child: _buildCameraItem(
                      selected: current == AppTab.scan,
                      onTap: () =>
                          _goTo(context, const ScanScreen(), AppTab.scan),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      selected: current == AppTab.profile,
                      onTap: () =>
                          _goTo(context, const ProfileScreen(), AppTab.profile),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Skips navigation when the tab is already showing.
  Future<void> _goTo(BuildContext context, Widget page, AppTab tab) async {
    if (current == tab) return;
    if (onBeforeLeave != null && !await onBeforeLeave!()) return;
    if (!context.mounted) return;
    Navigator.pushReplacement(context, noTransitionRoute(page));
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final inactiveColor = Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? _primaryColor : inactiveColor,
                size: 26,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? _primaryColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraItem({
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}
