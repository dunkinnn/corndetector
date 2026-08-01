import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/colors.dart';
import '../../widgets/brand_text_field.dart';
import '../home_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Sign in screen, matching the reference brand layout exactly.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _savePassword = true;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;

  // Inline error messages
  String? _emailError;
  String? _passwordError;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final savePref = prefs.getBool('save_password') ?? false;

    if (mounted) {
      setState(() {
        _savePassword = savePref;
        if (savedEmail != null) _emailController.text = savedEmail;
        if (savedPassword != null) _passwordController.text = savedPassword;
      });
    }
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool valid = true;

    setState(() {
      _emailError = email.isEmpty ? 'Email is required.' : null;
      _passwordError = password.isEmpty ? 'Password is required.' : null;
    });

    if (_emailError != null || _passwordError != null) {
      valid = false;
    }

    return valid;
  }

  // Placeholder submit handler; wire up real auth logic later.
  Future<void> _handleLogin() async {
    setState(() => _authError = null);

    if (!_validate()) return;

    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 400));

      // Handle saving/clearing credentials
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('save_password', _savePassword);

      if (_savePassword) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setString(
          'saved_password',
          _passwordController.text.trim(),
        );
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _authError = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.eco,
                  size: 100,
                  color: AppColors.brandGreen,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'MaisNutri',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandGreen,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Scan corn leaves. Detect deficiencies.\n'
                'Grow healthier crops.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.brandGreen,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 40),

              // ─── Auth-level error banner ──────────────────────────────────
              if (_authError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorRed.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.errorRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _authError!,
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              BrandTextField(
                hint: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                error: _emailError,
                onChanged: () => setState(() => _emailError = null),
              ),

              const SizedBox(height: 15),

              BrandTextField(
                hint: 'Password',
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                controller: _passwordController,
                error: _passwordError,
                onChanged: () => setState(() => _passwordError = null),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _savePassword,
                          activeColor: AppColors.brandGreen,
                          onChanged: (value) {
                            setState(() {
                              _savePassword = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Save Password',
                        style: TextStyle(
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
