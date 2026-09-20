import 'package:flutter/material.dart';

import 'core/colors.dart';
import 'screens/splash_screen.dart';

// Root widget: sets up theme and starts on the splash screen, which then
// routes to the tab shell or login once it's done showing.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaisNutri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandGreen),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
