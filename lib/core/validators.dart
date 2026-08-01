// Shared input validation helpers for auth forms.
class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  // Accepts digits with optional leading +, spaces, or dashes, 7-13 digits long.
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9\-\s]{7,15}$');

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digitCount = value.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (!_phonePattern.hasMatch(value.trim()) ||
        digitCount < 7 ||
        digitCount > 13) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
