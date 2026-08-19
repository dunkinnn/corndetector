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
    final authUser = supabase.auth.currentUser;
    final fallbackName =
        authUser?.userMetadata?['full_name'] as String? ?? '';
    final fallbackEmail = authUser?.email ?? '';

    if (row == null) {
      return UserProfile(
        id: userId,
        fullName: fallbackName,
        email: fallbackEmail,
      );
    }

    return UserProfile(
      id: row['id'] as String? ?? userId,
      fullName: (row['full_name'] as String?)?.trim().isNotEmpty == true
          ? row['full_name'] as String
          : fallbackName,
      email: (row['email'] as String?)?.trim().isNotEmpty == true
          ? row['email'] as String
          : fallbackEmail,
    );
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
