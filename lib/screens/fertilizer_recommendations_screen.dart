import 'package:flutter/material.dart';

import '../models/deficiency_reference.dart';
import '../services/reference_data_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

class FertilizerRecommendationsScreen extends StatefulWidget {
  const FertilizerRecommendationsScreen({super.key});

  @override
  State<FertilizerRecommendationsScreen> createState() =>
      _FertilizerRecommendationsScreenState();
}

class _FertilizerRecommendationsScreenState
    extends State<FertilizerRecommendationsScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _darkText = Color(0xFF1E293B);

  late final Future<List<DeficiencyReference>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = const ReferenceDataService()
        .getAll()
        .then((entries) => entries.where((e) => e.label != 'Healthy').toList());
  }

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
            FutureBuilder<List<DeficiencyReference>>(
              future: _recommendationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    ),
                  );
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.science_rounded,
                    title: 'No recommendations yet',
                    message:
                        'Scan a corn leaf first. Recommendations are generated from '
                        'the deficiency the scan identifies.',
                  );
                }
                return Column(children: entries.map(_buildEntryCard).toList());
              },
            ),
            const SizedBox(height: 110), // Space to avoid bottom bar overlap
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(DeficiencyReference entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 10),
          _buildRow(Icons.inventory_2_outlined, 'Fertilizer', entry.fertilizer),
          _buildRow(Icons.straighten_rounded, 'Rate', entry.rate),
          _buildRow(Icons.schedule_rounded, 'Timing', entry.timing),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: _darkText)),
          ),
        ],
      ),
    );
  }
}
