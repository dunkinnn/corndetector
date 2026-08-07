import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

class NutrientGuideScreen extends StatelessWidget {
  const NutrientGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Nutrient Guide',
        description: 'Symptoms and causes of each deficiency',
        showProfile: false,
        showBack: true,
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height:
                  MediaQuery.of(context).padding.top + AppTopBar.height + 20,
            ),
            const EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'Guide not available yet',
              message:
                  'Reference entries for nitrogen, phosphorus and potassium '
                  'deficiency will be listed here.',
            ),
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),
    );
  }
}
