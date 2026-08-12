import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _darkText = Color(0xFF1E293B);

  late final Future<List<ScanResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = const ScanService().getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Scan History',
        description: 'Past leaf scans and their results',
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
            FutureBuilder<List<ScanResult>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    ),
                  );
                }
                final scans = snapshot.data ?? [];
                if (scans.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No scans recorded',
                    message:
                        'Every leaf you scan will be listed here with its result '
                        'and the date it was taken.',
                  );
                }
                return Column(children: scans.map(_buildScanCard).toList());
              },
            ),
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard(ScanResult scan) {
    final color = scan.isHealthy ? _primaryColor : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              scan.isHealthy
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(scan.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '${(scan.confidence * 100).round()}%',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
