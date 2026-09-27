import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../services/profile_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/brand_text_field.dart';
import '../widgets/page_heading.dart';
import '../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await const ProfileService().getCurrentProfile();
    if (!mounted || profile == null) return;
    setState(() {
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await const ProfileService().updateFullName(_nameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save changes. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
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
          const PageHeading(kicker: 'Profile', title: 'Edit profile'),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.corn,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.isEmpty ? 'F' : name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'This is the name shown on your profile.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('Full name'),
          BrandTextField(
            hint: 'Enter your name',
            controller: _nameController,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 18),
          _buildLabel('Email address'),
          IgnorePointer(
            child: Opacity(
              opacity: 0.6,
              child: BrandTextField(
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Your email is used to sign in and cannot be changed here.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Save changes',
            onPressed: _save,
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
