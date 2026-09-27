import 'package:flutter/material.dart';

import '../core/colors.dart';

// Which peer tab is currently showing, so it can be highlighted.
enum AppTab { home, scan, profile, none }

// Bottom bar shared by the tab shell (see root_tab_screen.dart). Home, Scan,
// and Profile are peer tabs living in one IndexedStack, so switching tabs
// only changes which one is visible - it never rebuilds or refetches them.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onTabSelected,
    this.onBeforeLeave,
  });

  final AppTab current;

  // Switches the visible tab. Called after onBeforeLeave allows it.
  final ValueChanged<AppTab> onTabSelected;

  // Called before switching tabs; return false to cancel the navigation
  // (e.g. to warn about an unsaved scan result). Defaults to always allowing.
  final Future<bool> Function()? onBeforeLeave;

  static const double _barHeight = 76;

  @override
  Widget build(BuildContext context) {
    // Reserve space for the home indicator / gesture bar so labels never sit
    // flush against it; the white background still bleeds to the true edge.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: _barHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: current == AppTab.home,
              onTap: () => _goTo(AppTab.home),
            ),
          ),
          SizedBox(
            width: 88,
            child: Center(
              child: _buildCameraItem(
                selected: current == AppTab.scan,
                onTap: () => _goTo(AppTab.scan),
              ),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: current == AppTab.profile,
              onTap: () => _goTo(AppTab.profile),
            ),
          ),
        ],
      ),
    );
  }

  // Skips switching when the tab is already showing.
  Future<void> _goTo(AppTab tab) async {
    if (current == tab) return;
    if (onBeforeLeave != null && !await onBeforeLeave!()) return;
    onTabSelected(tab);
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const inactiveColor = AppColors.textMuted;
    const activeColor = AppColors.textDark;

    return InkWell(
      // Fills the full Expanded cell (via the Row's stretch above), and
      // InkWell hit-tests its whole bounds by default - no extra config
      // needed for the tap area to cover more than the icon/label.
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? activeColor : inactiveColor,
                size: 26,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Corn-yellow scan button; turns dark while the Scan tab is open.
  Widget _buildCameraItem({
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: 'Scan a leaf',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: selected ? AppColors.textDark : AppColors.corn,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.photo_camera_outlined,
            color: selected ? AppColors.corn : AppColors.textDark,
            size: 26,
          ),
        ),
      ),
    );
  }
}
