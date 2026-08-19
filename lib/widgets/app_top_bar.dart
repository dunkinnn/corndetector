import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../screens/deficiency_alerts_screen.dart';

/// Frosted-glass header shared by the Home and Profile screens.
/// Pair with `Scaffold(extendBodyBehindAppBar: true, ...)` and add a
/// `SizedBox(height: AppTopBar.height + MediaQuery.of(context).padding.top)`
/// at the top of the scrollable body so content clears the transparent bar.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  // Default (no args): brand header with logo + "MaisNutri" wordmark.
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
  static const Color _darkBlue = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

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
      centerTitle: hasCustomTitle,
      // Home and Profile are peer tabs, not a navigation stack.
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _darkBlue),
            )
          : null,
      // Frosted glass: blur whatever scrolls beneath, tinted white so dark
      // text stays legible, with a hairline edge to separate it from content.
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: hasCustomTitle
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
          : Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.eco, color: AppColors.brandGreen),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MAIS',
                      style: TextStyle(
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'NUTRI',
                      style: TextStyle(
                        color: _darkBlue,
                        fontSize: 10,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        IconButton(
          onPressed: () => _openNotifications(context),
          tooltip: 'Notifications',
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DeficiencyAlertsScreen(),
      ),
    );
  }
}
