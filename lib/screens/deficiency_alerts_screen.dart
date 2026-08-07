import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

class DeficiencyAlertsScreen extends StatelessWidget {
  const DeficiencyAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Deficiency Alerts',
        description: 'Nutrient deficiencies found in your scans',
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
              icon: Icons.warning_amber_rounded,
              title: 'No alerts yet',
              message:
                  'Alerts appear here when a scan detects a nitrogen, '
                  'phosphorus or potassium deficiency.',
            ),
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),
    );
  }
}
