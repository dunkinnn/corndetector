import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

// Hosts Home, Scan, and Profile as peer tabs in one IndexedStack instead of
// pushing/replacing routes between them. All three stay mounted, so
// switching tabs only changes which one is visible - it doesn't rebuild the
// others or re-run their initState data fetches every time.
class RootTabScreen extends StatefulWidget {
  const RootTabScreen({super.key});

  @override
  State<RootTabScreen> createState() => _RootTabScreenState();
}

class _RootTabScreenState extends State<RootTabScreen> {
  static const _tabs = [AppTab.home, AppTab.scan, AppTab.profile];

  int _index = 0;

  // Registered by ScanScreen while it's mounted (see ScanScreen's
  // onRegisterLeaveGuard), so switching away from Scan can still warn about
  // an unsaved result the same way it did when Scan owned its own bottom nav.
  Future<bool> Function()? _scanLeaveGuard;

  Future<void> _onTabSelected(AppTab tab) async {
    final targetIndex = _tabs.indexOf(tab);
    if (targetIndex == _index) return;
    if (_tabs[_index] == AppTab.scan && _scanLeaveGuard != null) {
      final canLeave = await _scanLeaveGuard!();
      if (!canLeave || !mounted) return;
    }
    setState(() => _index = targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          ScanScreen(
            onRegisterLeaveGuard: (guard) => _scanLeaveGuard = guard,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: _tabs[_index],
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
