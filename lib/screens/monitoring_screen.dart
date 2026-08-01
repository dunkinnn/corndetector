import 'package:flutter/material.dart';

/// Shows past corn leaf nutrient deficiency detections logged over time.
class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF388E3C);

    // Placeholder monitoring history; replace with real detection logs once
    // the YOLOv8 + EfficientNetB0 pipeline is wired up.
    final records = [
      _MonitoringRecord(
        date: 'Jul 28, 2026',
        deficiency: 'Nitrogen (N) Deficiency',
        location: 'Cubag, Cabagan',
        color: const Color(0xFFF9A825),
      ),
      _MonitoringRecord(
        date: 'Jul 21, 2026',
        deficiency: 'Healthy',
        location: 'Cubag, Cabagan',
        color: primaryColor,
      ),
      _MonitoringRecord(
        date: 'Jul 14, 2026',
        deficiency: 'Potassium (K) Deficiency',
        location: 'Cubag, Cabagan',
        color: const Color(0xFFE65100),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Monitoring',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
      body: records.isEmpty
          ? const Center(
              child: Text(
                'No monitoring records yet.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildRecordCard(records[index]),
            ),
    );
  }

  Widget _buildRecordCard(_MonitoringRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: record.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.eco_outlined, color: record.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.deficiency,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.date} • ${record.location}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.black26,
          ),
        ],
      ),
    );
  }
}

class _MonitoringRecord {
  const _MonitoringRecord({
    required this.date,
    required this.deficiency,
    required this.location,
    required this.color,
  });

  final String date;
  final String deficiency;
  final String location;
  final Color color;
}
