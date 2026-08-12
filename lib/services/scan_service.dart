import 'dart:io';

import '../core/supabase_config.dart';
import '../models/scan_result.dart';

// Persists leaf scan results and photos, and reads them back per user. A
// scan can hold more than one detection (a photo with more than one leaf
// or symptom area), so this writes one `scans` row plus one
// `scan_detections` row per detection.
class ScanService {
  const ScanService();

  static const _bucket = 'scan-photos';

  Future<ScanResult> saveScan({
    required List<Detection> detections,
    File? photo,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('No signed-in user.');
    if (detections.isEmpty) {
      throw ArgumentError('A scan needs at least one detection.');
    }

    String? imagePath;
    if (photo != null) {
      imagePath = '$userId/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await supabase.storage.from(_bucket).upload(imagePath, photo);
    }

    final scanRow = await supabase
        .from('scans')
        .insert({'user_id': userId, 'image_path': imagePath})
        .select()
        .single();
    final scanId = scanRow['id'] as String;

    final detectionRows = await supabase
        .from('scan_detections')
        .insert([
          for (final detection in detections)
            {
              'scan_id': scanId,
              'user_id': userId,
              ...detection.toInsertMap(),
            },
        ])
        .select();

    return ScanResult.fromMap({...scanRow, 'scan_detections': detectionRows});
  }

  Future<List<ScanResult>> getHistory() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await supabase
        .from('scans')
        .select('*, scan_detections(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(ScanResult.fromMap).toList();
  }

  // Signed URL for a stored photo, valid for one hour.
  Future<String> photoUrl(String imagePath) {
    return supabase.storage.from(_bucket).createSignedUrl(imagePath, 3600);
  }
}
