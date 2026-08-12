import '../core/supabase_config.dart';
import '../models/deficiency_reference.dart';

// Reads the shared nutrient deficiency reference data (symptoms and
// fertilizer guidance), seeded via supabase/schema.sql.
class ReferenceDataService {
  const ReferenceDataService();

  Future<List<DeficiencyReference>> getAll() async {
    final rows = await supabase
        .from('deficiency_reference')
        .select()
        .order('label');
    return rows.map(DeficiencyReference.fromMap).toList();
  }
}
