import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../screens/notifications_screen.dart';
import 'brand_wordmark.dart';
import 'circle_back_button.dart';

/// Flat header shared by the Home and Profile screens.
/// Pair with `Scaffold(extendBodyBehindAppBar: true, ...)` and add a
/// `SizedBox(height: AppTopBar.height + MediaQuery.of(context).padding.top)`
/// at the top of the scrollable body so content clears the transparent bar.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  // Default (no args): brand header with logo + "MaisNutri" wordmark.
  // With `showBack` and no title: just the back button, for pages that show
  // their own PageHeading.
  // Pass `title` (and optionally `description`) for a centered text header
  // instead, e.g. the Profile screen.
  const AppTopBar({
    super.key,
    this.title,
    this.description,
    this.showProfile = true,
    this.showBack = false,
  });

  final String? title;
  final String? description;
  final bool showProfile;

  // Set on pushed sub-screens so the user can get back.
  final bool showBack;

  static const double height = 70;
  static const Color _darkBlue = AppColors.textDark;
  static const Color _textSecondary = AppColors.textMuted;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final hasCustomTitle = title != null;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: height,
      leadingWidth: 64,
      centerTitle: hasCustomTitle,
      // Home and Profile are peer tabs, not a navigation stack.
      automaticallyImplyLeading: false,
      leading: showBack
          ? const Padding(
              padding: EdgeInsets.only(left: 12),
              child: CircleBackButton(),
            )
          : null,
      // Solid paper color so scrolled content never shows through.
      flexibleSpace: Container(color: AppColors.background),
      title: hasCustomTitle
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: _darkBlue,
                  ),
                ),
                if (description != null)
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            )
          : showBack
          ? null
          : Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.eco, color: AppColors.brandGreen),
                ),
                const SizedBox(width: 8),
                const BrandWordmark(),
              ],
            ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            onPressed: () => _openNotifications(context),
            tooltip: 'Notifications',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.card,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: _darkBlue,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  static const _notificationsRoute = '/notifications';

  void _openNotifications(BuildContext context) {
    // Skip if already on the notifications screen, so repeated taps don't
    // stack duplicate copies on the nav stack.
    if (ModalRoute.of(context)?.settings.name == _notificationsRoute) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: _notificationsRoute),
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }
}
