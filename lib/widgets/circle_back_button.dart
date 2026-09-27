import 'package:flutter/material.dart';

import '../core/colors.dart';

/// Round back button used on every pushed screen: a fixed-size circle with a
/// hairline border and a back arrow. Wrapped in [Center] so parents that pass
/// tight constraints (like the AppBar `leading` slot) can't stretch it into
/// an oval or pill.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({
    super.key,
    this.onPressed,
    this.size = 44,
    this.backgroundColor = AppColors.card,
    this.iconColor = AppColors.textDark,
    this.showBorder = true,
  });

  /// Defaults to `Navigator.maybePop(context)`.
  final VoidCallback? onPressed;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: backgroundColor,
          shape: CircleBorder(
            side: showBorder
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed ?? () => Navigator.maybePop(context),
            child: Tooltip(
              message: 'Back',
              child: Icon(
                Icons.arrow_back_rounded,
                color: iconColor,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
