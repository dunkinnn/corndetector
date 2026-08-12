import '../core/supabase_config.dart';

// Thin wrapper around Supabase Auth for sign up, sign in, sign out, and
// password reset.
class AuthService {
  const AuthService();

  bool get isSignedIn => supabase.auth.currentSession != null;

  Future<void> signIn({required String email, required String password}) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Returns true if the session is active immediately (email confirmation
  // disabled on the project), false if a confirmation email was sent instead.
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return response.session != null;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() {
    return supabase.auth.signOut();
  }
}
