import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/validators.dart';
import '../services/auth_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/brand_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _darkText = Color(0xFF1E293B);

  final AuthService _auth = const AuthService();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _currentError = _currentController.text.isEmpty
          ? 'Current password is required'
          : null;
      _newError = Validators.password(_newController.text);
      _confirmError = Validators.confirmPassword(
        _confirmController.text,
        _newController.text,
      );
    });
    return _currentError == null && _newError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    if (_isSaving || !_validate()) return;
    setState(() => _isSaving = true);
    try {
      await _auth.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      setState(() => _currentError = e.message);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update password. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: 'Change Password',
        description: 'Update your account password',
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

            _buildLabel('Current Password'),
            BrandTextField(
              hint: 'Enter your current password',
              controller: _currentController,
              isPassword: true,
              obscureText: _obscureCurrent,
              error: _currentError,
              onToggleObscure: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
              onChanged: () => setState(() => _currentError = null),
            ),
            const SizedBox(height: 18),

            _buildLabel('New Password'),
            BrandTextField(
              hint: 'At least 8 characters',
              controller: _newController,
              isPassword: true,
              obscureText: _obscureNew,
              error: _newError,
              onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              onChanged: () => setState(() => _newError = null),
            ),
            const SizedBox(height: 18),

            _buildLabel('Confirm New Password'),
            BrandTextField(
              hint: 'Re-enter your new password',
              controller: _confirmController,
              isPassword: true,
              obscureText: _obscureConfirm,
              error: _confirmError,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              onChanged: () => setState(() => _confirmError = null),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update Password',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _darkText,
        ),
      ),
    );
  }
}
