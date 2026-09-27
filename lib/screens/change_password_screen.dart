import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/colors.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/brand_text_field.dart';
import '../widgets/page_heading.dart';
import '../widgets/primary_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(showProfile: false, showBack: true),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + AppTopBar.height + 8,
          20,
          32,
        ),
        children: [
          const PageHeading(kicker: 'Security', title: 'Change password'),
          _buildLabel('Current password'),
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
          _buildLabel('New password'),
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
          _buildLabel('Confirm new password'),
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
          PrimaryButton(
            label: 'Update password',
            onPressed: _submit,
            isLoading: _isSaving,
          ),
        ],
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
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
