import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/detection_alert_card.dart';
import '../widgets/empty_state.dart';

// One non-healthy detection plus the date of the scan it came from - a scan
// can hold several detections, so alerts are flattened to one per
// detection rather than one per scan.
class _AlertItem {
  const _AlertItem({required this.detection, required this.scanDate});

  final Detection detection;
  final DateTime scanDate;
}

class DeficiencyAlertsScreen extends StatefulWidget {
  const DeficiencyAlertsScreen({super.key});

  @override
  State<DeficiencyAlertsScreen> createState() =>
      _DeficiencyAlertsScreenState();
}

class _DeficiencyAlertsScreenState extends State<DeficiencyAlertsScreen> {
  late final Future<List<_AlertItem>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = const ScanService().getHistory().then(
      (scans) => [
        for (final scan in scans)
          for (final detection in scan.detections)
            if (!detection.isHealthy)
              _AlertItem(detection: detection, scanDate: scan.createdAt),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            FutureBuilder<List<_AlertItem>>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                final alerts = snapshot.data ?? [];
                if (alerts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.warning_amber_rounded,
                    title: 'No alerts yet',
                    message:
                        'Alerts appear here when a scan detects a nitrogen, '
                        'phosphorus or potassium deficiency.',
                  );
                }
                return Column(children: alerts.map(_buildAlertCard).toList());
              },
            ),
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(_AlertItem item) {
    return DetectionAlertCard(
      detection: item.detection,
      scanDate: item.scanDate,
    );
  }
}
