import 'package:flutter/material.dart';

import 'core/colors.dart';
import 'core/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

// Root widget: sets up theme and starts on Home if a Supabase session is
// already active, otherwise the login screen.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final isSignedIn = supabase.auth.currentSession != null;

    return MaterialApp(
      title: 'Corn Leaf Nutrient Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandGreen),
        useMaterial3: true,
      ),
      home: isSignedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
