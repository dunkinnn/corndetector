import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/detection_alert_card.dart';
import '../widgets/empty_state.dart';

// One non-healthy detection plus the date of the scan it came from - a scan
// can hold several detections, so notifications are flattened to one per
// detection rather than one per scan.
class _NotificationItem {
  const _NotificationItem({required this.detection, required this.scanDate});

  final Detection detection;
  final DateTime scanDate;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final Future<List<_NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = const ScanService().getHistory().then(
      (scans) => [
        for (final scan in scans)
          for (final detection in scan.detections)
            if (!detection.isHealthy)
              _NotificationItem(detection: detection, scanDate: scan.createdAt),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Notifications',
        description: 'Recent scan alerts and crop updates',
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
            FutureBuilder<List<_NotificationItem>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    message:
                        'When a scan finds a deficiency, it will appear here.',
                  );
                }
                return Column(children: items.map(_buildItemCard).toList());
              },
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(_NotificationItem item) {
    return DetectionAlertCard(
      detection: item.detection,
      scanDate: item.scanDate,
    );
  }
}
