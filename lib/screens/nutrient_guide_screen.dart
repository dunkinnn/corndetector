import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../models/deficiency_reference.dart';
import '../services/reference_data_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/nutrient_dot.dart';

class NutrientGuideScreen extends StatefulWidget {
  const NutrientGuideScreen({super.key});

  @override
  State<NutrientGuideScreen> createState() => _NutrientGuideScreenState();
}

class _NutrientGuideScreenState extends State<NutrientGuideScreen> {
  static const Color _primaryColor = AppColors.primary;
  static const Color _bgCanvas = AppColors.background;
  static const Color _textMain = AppColors.textDark;
  static const Color _textMuted = AppColors.textMuted;

  late final Future<List<DeficiencyReference>> _guideFuture;

  List<DeficiencyReference> _allEntries = [];
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _guideFuture = const ReferenceDataService().getAll();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.of(context).padding.top + AppTopBar.height + 20;

    return Scaffold(
      backgroundColor: _bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Nutrient Guide',
        description: 'Symptoms and causes of crop deficiencies',
        showProfile: false,
        showBack: true,
      ),
      body: FutureBuilder<List<DeficiencyReference>>(
        future: _guideFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 2.5,
              ),
            );
          }

          if (!_isDataLoaded && snapshot.hasData) {
            _allEntries = snapshot.data ?? [];
            _isDataLoaded = true;
          }

          if (_allEntries.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const EmptyState(
                icon: Icons.menu_book_rounded,
                title: 'Guide Not Available',
                message:
                    'Reference entries for nitrogen, phosphorus, and potassium '
                    'deficiencies will be listed here.',
              ),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(16.0, topPadding, 16.0, 40.0),
            children: [
              // --- List of Cards ---
              if (_allEntries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No matching nutrient deficiency found.',
                    style: TextStyle(color: _textMuted, fontSize: 14),
                  ),
                )
              else
                ..._allEntries.map(_buildExpandableNutrientCard),
            ],
          );
        },
      ),
    );
  }

  // --- Expandable Nutrient Card Component ---
  Widget _buildExpandableNutrientCard(DeficiencyReference entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                NutrientDot(label: entry.label, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        entry.symptom,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
