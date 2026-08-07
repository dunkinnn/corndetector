import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

class FertilizerRecommendationsScreen extends StatelessWidget {
  const FertilizerRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Fertilizer Recommendations',
        description: 'Suggested dosage and application timing',
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
              icon: Icons.science_rounded,
              title: 'No recommendations yet',
              message:
                  'Scan a corn leaf first. Recommendations are generated from '
                  'the deficiency the scan identifies.',
            ),
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),
    );
  }
}
