import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/colors.dart';
import '../core/supabase_config.dart';
import 'auth/login_screen.dart';
import 'root_tab_screen.dart';

// Branded splash shown briefly on launch, then routes to the tab shell or
// login depending on whether a Supabase session is already active.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for the first frame to actually paint before starting the
    // delay timer - on a slow cold start (heavy plugin init, etc.) the
    // timer would otherwise fire before this screen was ever visible.
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  // Short pause so the splash reads as a deliberate loading step rather than
  // a flash - the actual auth check itself is already resolved by main().
  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final isSignedIn = supabase.auth.currentSession != null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            isSignedIn ? const RootTabScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.eco,
                size: 100,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              AppInfo.name,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Detect. Classify. Grow better.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                color: AppColors.brandGreen,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
