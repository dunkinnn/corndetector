import 'package:flutter/material.dart';

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

  static const Color _primaryColor = Color(0xFF2E7D32);

  static const double _barHeight = 86;

  @override
  Widget build(BuildContext context) {
    // Reserve space for the home indicator / gesture bar so labels never sit
    // flush against it; the white background still bleeds to the true edge.
    final bottomInset = MediaQuery.of(context).padding.bottom;

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
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: _barHeight + bottomInset,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
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
                    width: 80,
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
            ),
          ),
        ),
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
    // shade600 clears WCAG AA contrast against white; shade400 didn't.
    final inactiveColor = Colors.grey.shade600;

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
                color: selected ? _primaryColor : inactiveColor,
                size: 28,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Container(
          width: 64,
          height: 64,
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
            size: 26,
          ),
        ),
      ),
    );
  }
}
