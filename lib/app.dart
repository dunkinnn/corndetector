import 'package:flutter/material.dart';

import 'core/colors.dart';
import 'screens/auth/login_screen.dart';

// Root widget: sets up theme and starts on the login screen.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corn Leaf Nutrient Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandGreen),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
