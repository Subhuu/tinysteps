import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String message, {Color? color, IconData? icon}) {
    final bg = color ?? AppColors.textDark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    final email = _supabase.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      _snack(
        'No email found for this account.',
        color: AppColors.danger,
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _snack(
        'Password reset email sent to $email',
        color: AppColors.success,
        icon: Icons.mark_email_read_outlined,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _snack(
        e.message,
        color: AppColors.danger,
        icon: Icons.error_outline,
      );
    } catch (_) {
      if (!mounted) return;
      _snack(
        'Could not send reset email. Try again.',
        color: AppColors.danger,
        icon: Icons.wifi_off_rounded,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _supabase.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      _snack(
        'No email found for this account.',
        color: AppColors.danger,
        icon: Icons.error_outline,
      );
      return;
    }

    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (next != confirm) {
      _snack(
        'New passwords do not match.',
        color: AppColors.danger,
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Re-auth to verify current password (required for security).
      await _supabase.auth.signInWithPassword(
        email: email,
        password: current,
      );

      await _supabase.auth.updateUser(
        UserAttributes(password: next),
      );

      if (!mounted) return;
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();

      _snack(
        'Password updated successfully.',
        color: AppColors.success,
        icon: Icons.check_circle_outline,
      );
      Navigator.of(context).maybePop();
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') || msg.contains('credentials')) {
        _snack(
          'Current password is incorrect.',
          color: AppColors.danger,
          icon: Icons.lock_outline_rounded,
        );
      } else {
        _snack(
          e.message,
          color: AppColors.danger,
          icon: Icons.error_outline,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _snack(
        'Could not update password. Check your connection and try again.',
        color: AppColors.danger,
        icon: Icons.wifi_off_rounded,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Change Password', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? null : AppGradients.sunrise,
          color: isDark ? AppColors.bgDark : null,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: AbsorbPointer(
                  absorbing: _loading,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'For security, you’ll need your current password. '
                                'Choose a strong new password (min 8 characters).',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.textDarkMode : AppColors.textMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? AppColors.bgDarkSurface.withValues(alpha: 0.95)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.card,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Update your password',
                                style: AppTextStyles.heading3,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Your new password will be used the next time you sign in.',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              TextFormField(
                                controller: _currentCtrl,
                                obscureText: _obscureCurrent,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Current password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureCurrent = !_obscureCurrent,
                                    ),
                                    icon: Icon(
                                      _obscureCurrent
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.length < 6) return 'Too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _newCtrl,
                                obscureText: _obscureNew,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'New password',
                                  prefixIcon: const Icon(Icons.password_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscureNew = !_obscureNew),
                                    icon: Icon(
                                      _obscureNew
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.length < 8) return 'Min 8 characters';
                                  if (v == _currentCtrl.text) {
                                    return 'New password must be different';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _confirmCtrl,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _changePassword(),
                                decoration: InputDecoration(
                                  labelText: 'Confirm new password',
                                  prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v != _newCtrl.text) return 'Does not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.buttonRadius,
                                    ),
                                  ),
                                  onPressed: _changePassword,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text('Update Password',
                                          style: AppTextStyles.buttonLabel),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextButton(
                                onPressed: _sendResetEmail,
                                child: Text(
                                  'Forgot current password? Send reset email',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


