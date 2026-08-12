import '../core/supabase_config.dart';
import '../models/user_profile.dart';

// Reads and updates the signed-in user's row in the `profiles` table.
class ProfileService {
  const ProfileService();

  Future<UserProfile?> getCurrentProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : UserProfile.fromMap(row);
  }

  Future<void> updateFullName(String fullName) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', userId);
  }
}
