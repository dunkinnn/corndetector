import 'package:flutter/material.dart';

import '../core/no_transition_route.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

// Which peer tab is currently showing, so it can be highlighted.
enum AppTab { home, profile, none }

// Bottom bar shared by every top-level screen, with a notch for the scan
// button. Home and Profile are peer tabs, so they replace each other.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current});

  final AppTab current;

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
  void _goTo(BuildContext context, Widget page, AppTab tab) {
    if (current == tab) return;
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

// Centre scan button that docks into the bottom bar notch.
class AppScanButton extends StatelessWidget {
  const AppScanButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const Color _primaryColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      width: 76,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: _primaryColor,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.camera_alt_rounded,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}
