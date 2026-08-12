import 'dart:io';

import '../core/supabase_config.dart';
import '../models/scan_result.dart';

// Persists leaf scan results and photos, and reads them back per user.
class ScanService {
  const ScanService();

  static const _bucket = 'scan-photos';

  Future<ScanResult> saveScan({
    required String label,
    required double confidence,
    required String symptom,
    required String fertilizer,
    required String rate,
    required String timing,
    required String note,
    File? photo,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('No signed-in user.');

    String? imagePath;
    if (photo != null) {
      imagePath = '$userId/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await supabase.storage.from(_bucket).upload(imagePath, photo);
    }

    final row = await supabase
        .from('scans')
        .insert({
          'user_id': userId,
          'image_path': imagePath,
          'label': label,
          'confidence': confidence,
          'symptom': symptom,
          'fertilizer': fertilizer,
          'rate': rate,
          'timing': timing,
          'note': note,
        })
        .select()
        .single();

    return ScanResult.fromMap(row);
  }

  Future<List<ScanResult>> getHistory() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await supabase
        .from('scans')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(ScanResult.fromMap).toList();
  }

  // Signed URL for a stored photo, valid for one hour.
  Future<String> photoUrl(String imagePath) {
    return supabase.storage.from(_bucket).createSignedUrl(imagePath, 3600);
  }
}
