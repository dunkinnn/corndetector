import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
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
  static const Color _textMain = Color(0xFF1E293B);
  static const Color _alertColor = Color(0xFFDC2626);

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
      backgroundColor: const Color(0xFFF8FAF8),
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
                      child: CircularProgressIndicator(color: _alertColor),
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
              const Icon(
                Icons.warning_amber_rounded,
                color: _alertColor,
                size: 20,
              ),
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
            style: const TextStyle(fontSize: 13, color: _textMain, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.scanDate.month}/${item.scanDate.day}/${item.scanDate.year}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
