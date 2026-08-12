import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
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
  static const Color _darkText = Color(0xFF1E293B);
  static const Color _alertColor = Color(0xFFDC2626);

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
            FutureBuilder<List<_AlertItem>>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: _alertColor),
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
    final detection = item.detection;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _alertColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _alertColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detection.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _alertColor,
                  ),
                ),
              ),
              Text(
                '${(detection.confidence * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _alertColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detection.symptom,
            style: const TextStyle(fontSize: 13, color: _darkText, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(item.scanDate),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
