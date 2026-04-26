import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password updated successfully!'),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: context.colors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgLight,
      body: Stack(
        children: [
          // ── Background Gradient ───────────────────────────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFD4C2),
                  context.colors.bgLight,
                ],
              ),
            ),
          ),

          // ── Decorative Circles ────────────────────────────────────────────
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: context.colors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Change Password',
                    style: context.textStyles.heading2,
                  ),
                  centerTitle: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.md),
                      
                      // ── Glassmorphic Card ─────────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: context.colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: context.colors.white.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Update your security',
                                    style: context.textStyles.heading3,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Ensure your account stays protected with a strong password.',
                                    style: context.textStyles.bodyMuted,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Current Password
                                  _buildFieldLabel('Current Password'),
                                  TextFormField(
                                    controller: _currentPasswordController,
                                    obscureText: _obscureCurrent,
                                    decoration: InputDecoration(
                                      hintText: 'Enter current password',
                                      prefixIcon: const Icon(Icons.lock_open_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureCurrent
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // New Password
                                  _buildFieldLabel('New Password'),
                                  TextFormField(
                                    controller: _newPasswordController,
                                    obscureText: _obscureNew,
                                    decoration: InputDecoration(
                                      hintText: 'Minimum 6 characters',
                                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureNew
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Required';
                                      if (v.length < 6) return 'At least 6 chars';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // Confirm Password
                                  _buildFieldLabel('Confirm New Password'),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirm,
                                    decoration: InputDecoration(
                                      hintText: 'Repeat new password',
                                      prefixIcon: const Icon(Icons.verified_user_outlined),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v != _newPasswordController.text) return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: AppGradients.coralButton,
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                        boxShadow: AppShadows.button,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _updatePassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppRadius.full),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'Update Password',
                                                style: context.textStyles.buttonLabel,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Tips section
                      _buildTip(
                        Icons.info_outline_rounded,
                        'Use a mix of letters, numbers, and symbols for a stronger password.',
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.xs),
      child: Text(
        label,
        style: context.textStyles.labelMedium.copyWith(color: context.colors.textMedium),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.colors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodySmall.copyWith(color: context.colors.textMedium),
            ),
          ),
        ],
      ),
    );
  }
}
