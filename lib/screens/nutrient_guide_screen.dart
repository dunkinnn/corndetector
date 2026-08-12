import 'package:flutter/material.dart';

import '../models/deficiency_reference.dart';
import '../services/reference_data_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

class NutrientGuideScreen extends StatefulWidget {
  const NutrientGuideScreen({super.key});

  @override
  State<NutrientGuideScreen> createState() => _NutrientGuideScreenState();
}

class _NutrientGuideScreenState extends State<NutrientGuideScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _darkText = Color(0xFF1E293B);

  late final Future<List<DeficiencyReference>> _guideFuture;

  @override
  void initState() {
    super.initState();
    _guideFuture = const ReferenceDataService().getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Nutrient Guide',
        description: 'Symptoms and causes of each deficiency',
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
              future: _guideFuture,
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
                    icon: Icons.menu_book_rounded,
                    title: 'Guide not available yet',
                    message:
                        'Reference entries for nitrogen, phosphorus and potassium '
                        'deficiency will be listed here.',
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
          const SizedBox(height: 8),
          Text(
            entry.symptom,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }
}
