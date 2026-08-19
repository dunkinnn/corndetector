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
  static const Color _bgCanvas = Color(0xFFF4F6F4);
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

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
      backgroundColor: _bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Fertilizer Recommendations',
        description: 'Suggested dosage and application timing',
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
    final themeColor = _getNutrientColor(entry.label);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.science_rounded,
                      color: themeColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.fertilizer,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildRow(Icons.straighten_rounded, 'Rate', entry.rate),
            _buildRow(Icons.schedule_rounded, 'Timing', entry.timing),
            if (entry.note.trim().isNotEmpty) ...[
              _buildRow(Icons.info_outline_rounded, 'Note', entry.note),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: _textMain, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNutrientColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('nitrogen')) return const Color(0xFF16A34A);
    if (lower.contains('phosphorus')) return const Color(0xFFEA580C);
    if (lower.contains('potassium')) return const Color(0xFF2563EB);
    if (lower.contains('healthy')) return const Color(0xFF059669);
    return _primaryColor;
  }
}
