import 'package:flutter/material.dart';

/// Route with no transition animation, used when switching between top-level
/// tabs (e.g. Home/Monitoring) so it feels instant instead of sliding in.
Route<T> noTransitionRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
