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
  static const Color _bgCanvas = Color(0xFFF4F6F4);
  static const Color _textMuted = Color(0xFF64748B);

  late final Future<List<ScanResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = const ScanService().getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Scan History',
        description: 'Past leaf scans and their results',
        showProfile: false,
        showBack: true,
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

  // A scan can hold more than one detection (photo had more than one leaf
  // or symptom area), so the label/confidence pair from the old single-
  // detection card is now one chip per detection instead of a fixed column.
  Widget _buildScanCard(ScanResult scan) {
    final color = scan.isHealthy ? _primaryColor : const Color(0xFFDC2626);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScanHistoryDetailScreen(scan: scan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 104),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: scan.detections
                          .map(_buildDetectionChip)
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(scan.createdAt),
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionChip(Detection detection) {
    final color = detection.isHealthy ? _primaryColor : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${detection.label} ${(detection.confidence * 100).round()}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class ScanHistoryDetailScreen extends StatelessWidget {
  const ScanHistoryDetailScreen({super.key, required this.scan});

  final ScanResult scan;

  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _bgCanvas = Color(0xFFF4F6F4);
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: 'Scan Details',
        description: '${scan.detections.length} detections',
        showProfile: false,
        showBack: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height:
                  MediaQuery.of(context).padding.top + AppTopBar.height + 20,
            ),
            if (scan.imagePath != null) ...[
              FutureBuilder<String>(
                future: const ScanService().photoUrl(scan.imagePath!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Container(
                      width: double.infinity,
                      height: 220,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: _primaryColor),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Container(
                      width: double.infinity,
                      height: 220,
                      margin: const EdgeInsets.only(bottom: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Image unavailable',
                        style: TextStyle(color: _textMuted),
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Text(
                                'Image unavailable',
                                style: TextStyle(color: _textMuted),
                              ),
                            ),
                      ),
                    ),
                  );
                },
              ),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.isHealthy ? 'Healthy Scan' : 'Deficient Scan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${scan.createdAt.month}/${scan.createdAt.day}/${scan.createdAt.year}',
                    style: const TextStyle(fontSize: 12, color: _textMuted),
                  ),
                  const SizedBox(height: 14),
                  ...scan.detections.map((detection) {
                    final color = detection.isHealthy
                        ? _primaryColor
                        : const Color(0xFFDC2626);
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detection.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            detection.symptom,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textMain,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Confidence: ${(detection.confidence * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fertilizer: ${detection.fertilizer}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                          Text(
                            'Rate: ${detection.rate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                          Text(
                            'Timing: ${detection.timing}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                          Text(
                            'Note: ${detection.note}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
