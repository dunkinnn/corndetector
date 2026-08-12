import 'package:flutter/material.dart';

import '../core/no_transition_route.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

// Which peer tab is currently showing, so it can be highlighted.
enum AppTab { home, profile, none }

// Bottom bar shared by every top-level screen, with a notch for the scan
// button. Home and Profile are peer tabs, so they replace each other.
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
            height: 76,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: current == AppTab.home,
                  onTap: () => _goTo(context, const HomeScreen(), AppTab.home),
                ),

                // Spacer for the center scan button.
                const SizedBox(width: 64),

                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: current == AppTab.profile,
                  onTap: () =>
                      _goTo(context, const ProfileScreen(), AppTab.profile),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? _primaryColor : inactiveColor,
                size: 32,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
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
}

// Centre scan button that docks into the bottom bar notch. A white ring
// (matching the bar's own surface color) seats it flush into the notch
// instead of the old oversized translucent halo, which read as a loose
// floating circle rather than a button anchored to the bar.
class AppScanButton extends StatelessWidget {
  const AppScanButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const Color _primaryColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      width: 68,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton(
        // Every screen has its own instance of this button; without an
        // explicit tag they'd all share Flutter's default hero tag, which
        // makes it flight-animate (visible as a twitch) between screens.
        heroTag: null,
        onPressed: onPressed,
        backgroundColor: _primaryColor,
        elevation: 1,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.camera_alt_rounded,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}
