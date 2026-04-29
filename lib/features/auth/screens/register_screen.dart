import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/features/auth/widgets/auth_widgets.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RegisterScreen — Multi-step signup
//   Step 0: Role selection (Parent / Teacher / Admin)
//   Step 1: Account details (all roles)
//   Step 2 (Parents only): First child info
// ─────────────────────────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _step1Key = GlobalKey<FormState>(); // Login details
  final _step2Key = GlobalKey<FormState>(); // Profile details
  final _step3Key = GlobalKey<FormState>(); // Child details

  int _step = 0;
  String _selectedRole = 'parent';
  bool _loading = false;

  // ── Common controllers ────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  // ── Parent-specific ───────────────────────────────────────────────────
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _relationCtrl = TextEditingController();

  // ── Parent: first child ───────────────────────────────────────────────
  final _childNameCtrl = TextEditingController();
  DateTime? _childDob;
  String _childGender = 'male';
  final _childAllergyCtrl = TextEditingController();
  final _childMedCtrl = TextEditingController();
  final _classroomCodeCtrl = TextEditingController(); // optional classroom code

  // ── Teacher-specific ──────────────────────────────────────────────────
  final _staffIdCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();

  // ── Admin-specific ────────────────────────────────────────────────────
  final _centerNameCtrl = TextEditingController();
  final _adminDesigCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Animation
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  void _goToStep(int step) {
    _animCtrl.reset();
    setState(() => _step = step);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _nameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl,
      _referralCtrl, _emergencyNameCtrl, _emergencyPhoneCtrl, _relationCtrl,
      _childNameCtrl, _childAllergyCtrl, _childMedCtrl, _classroomCodeCtrl,
      _staffIdCtrl, _designationCtrl, _centerNameCtrl, _adminDesigCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final meta = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        'role': _selectedRole,
        'phone': _phoneCtrl.text.trim(),
        'referral_code': _referralCtrl.text.trim(),
      };

      switch (_selectedRole) {
        case 'parent':
          meta['emergency_contact_name'] = _emergencyNameCtrl.text.trim();
          meta['emergency_contact_phone'] = _emergencyPhoneCtrl.text.trim();
          meta['relationship'] = _relationCtrl.text.trim();
          meta['child_name'] = _childNameCtrl.text.trim();
          meta['child_dob'] = _childDob != null
              ? _childDob!.toIso8601String().split('T').first : '';
          meta['child_gender'] = _childGender;
          meta['child_allergies'] = _childAllergyCtrl.text.trim();
          meta['child_medical_notes'] = _childMedCtrl.text.trim();
          // Classroom code — trigger resolves classroom_id + teacher_id
          meta['child_classroom_code'] = _classroomCodeCtrl.text.trim().toUpperCase();
          break;
        case 'teacher':
          meta['staff_id'] = _staffIdCtrl.text.trim();
          meta['designation'] = _designationCtrl.text.trim().isEmpty
              ? 'Teacher' : _designationCtrl.text.trim();
          break;
        case 'admin':
          meta['center_name'] = _centerNameCtrl.text.trim();
          meta['designation'] = _adminDesigCtrl.text.trim().isEmpty
              ? 'Center Director' : _adminDesigCtrl.text.trim();
          break;
      }

      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        data: meta,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Account created! Check your email to verify.')),
          ]),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          duration: const Duration(seconds: 5),
        ));
        context.go('/login');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('user already registered') ||
          msg.contains('email already in use') ||
          msg.contains('already been registered')) {
        _showEmailInUseDialog();
      } else {
        _showError('Signup failed: ${e.message}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEmailInUseDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? context.colors.bgDarkSurface : context.colors.bgSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl)),
          icon: Icon(Icons.email_outlined,
              color: context.colors.primary, size: 36),
          title: Text(
            'Email already registered',
            style: context.textStyles.heading3.copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'An account with this email already exists. Did you mean to sign in instead?',
            style: context.textStyles.bodyMedium
                .copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Stay here',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
              child: const Text('Sign in instead'),
            ),
          ],
        );
      },
    );
  }


  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: context.colors.danger,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSteps = _selectedRole == 'parent' ? 4 : 3;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Subtle background blobs
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.secondary
                    .withValues(alpha: isDark ? 0.08 : 0.10),
              ),
            ),
          ),

          SafeArea(
            child: AbsorbPointer(
              absorbing: _loading,
              child: Column(
                children: [
                  // ── App bar ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          color: cs.onSurface,
                          onPressed: () {
                            if (_step > 0) {
                              _goToStep(_step - 1);
                            } else {
                              context.go('/login');
                            }
                          },
                        ),
                        const Spacer(),
                        if (_step > 0)
                          _StepIndicator(
                              current: _step, total: totalSteps),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _buildCurrentStep(isDark, cs),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading spinner overlay ─────────────────────────────────
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.18),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark
                        ? context.colors.bgDarkSurface
                        : context.colors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.floating,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: context.colors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Setting up your account…',
                          style: context.textStyles.bodyMedium
                              .copyWith(color: context.colors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildCurrentStep(bool isDark, ColorScheme cs) {
    switch (_step) {
      case 0:
        return _RoleSelectionStep(
          selected: _selectedRole,
          onSelect: (role) {
            _selectedRole = role;
            _goToStep(1);
          },
          onLogin: () => context.go('/login'),
          cs: cs,
          isDark: isDark,
        );
      case 1:
        return _LoginStep(
          formKey: _step1Key,
          emailCtrl: _emailCtrl,
          passCtrl: _passCtrl,
          confirmCtrl: _confirmCtrl,
          obscurePass: _obscurePass,
          obscureConfirm: _obscureConfirm,
          onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
          onToggleConfirm: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          isDark: isDark,
          cs: cs,
          onNext: () {
            if (_step1Key.currentState!.validate()) {
              _goToStep(2);
            }
          },
        );
      case 2:
        return _ProfileStep(
          formKey: _step2Key,
          role: _selectedRole,
          nameCtrl: _nameCtrl,
          phoneCtrl: _phoneCtrl,
          referralCtrl: _referralCtrl,
          emergencyNameCtrl: _emergencyNameCtrl,
          emergencyPhoneCtrl: _emergencyPhoneCtrl,
          relationCtrl: _relationCtrl,
          staffIdCtrl: _staffIdCtrl,
          designationCtrl: _designationCtrl,
          centerNameCtrl: _centerNameCtrl,
          adminDesigCtrl: _adminDesigCtrl,
          isDark: isDark,
          cs: cs,
          loading: _loading,
          onNext: () {
            if (_step2Key.currentState!.validate()) {
              if (_selectedRole == 'parent') {
                _goToStep(3); // Parents fill child info next
              } else {
                _submit(); // Others go straight to submit
              }
            }
          },
        );
      case 3:
        return _ChildInfoStep(
          formKey: _step3Key,
          childNameCtrl: _childNameCtrl,
          childDob: _childDob,
          childGender: _childGender,
          allergyCtrl: _childAllergyCtrl,
          medCtrl: _childMedCtrl,
          classroomCodeCtrl: _classroomCodeCtrl,
          isDark: isDark,
          cs: cs,
          loading: _loading,
          onPickDob: _pickDob,
          onGenderChange: (v) => setState(() => _childGender = v!),
          onSubmit: () {
            if (_step3Key.currentState!.validate()) {
              if (_childDob == null) {
                _showError('Please select your child\'s date of birth.');
                return;
              }
              _submit();
            }
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: context.colors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _childDob = picked);
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// STEP 0 — Role Selection
// ───────────────────────────────────────────────────────────────────────────────
class _RoleSelectionStep extends StatefulWidget {
  const _RoleSelectionStep({
    required this.selected,
    required this.onSelect,
    required this.onLogin,
    required this.cs,
    required this.isDark,
  });
  final String selected;
  final void Function(String) onSelect;
  final VoidCallback onLogin;
  final ColorScheme cs;
  final bool isDark;

  @override
  State<_RoleSelectionStep> createState() => _RoleSelectionStepState();
}

class _RoleSelectionStepState extends State<_RoleSelectionStep> {
  bool _showStaffOptions = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),

        // ── Heading ──────────────────────────────────────────────────
        ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [context.colors.primary, context.colors.secondary],
          ).createShader(b),
          child: Text('Create account',
              style: GoogleFonts.lexend(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Welcome — let\'s get you set up',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),

        const SizedBox(height: AppSpacing.xxl),

        // ── Parent hero card (primary CTA) ───────────────────────────
        _ParentHeroCard(
          isDark: isDark,
          cs: cs,
          onTap: () => widget.onSelect('parent'),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Staff/Admin hidden section ───────────────────────────────
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _showStaffOptions = !_showStaffOptions),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _showStaffOptions
                      ? 'Hide staff options'
                      : 'Are you staff or admin?',
                  style: context.textStyles.bodySmall.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    decoration: TextDecoration.underline,
                    decorationColor: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showStaffOptions
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),

        // ── Animated staff/admin tiles ───────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState: _showStaffOptions
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Column(
              children: [
                // Info note
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: context.colors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16,
                          color: context.colors.accent.withValues(alpha: 0.8)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Staff & admin accounts require a referral code from the center.',
                          style: context.textStyles.bodySmall.copyWith(
                              color: context.colors.accent
                                  .withValues(alpha: 0.85)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _CompactRoleCard(
                  icon: Icons.school_rounded,
                  title: 'Teacher / Staff',
                  subtitle: 'I work at the daycare',
                  color: context.colors.secondary,
                  isDark: isDark,
                  onTap: () => widget.onSelect('teacher'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _CompactRoleCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin',
                  subtitle: 'I manage the center',
                  color: context.colors.accent,
                  isDark: isDark,
                  onTap: () => widget.onSelect('admin'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Already have account ─────────────────────────────────────
        Center(
          child: GestureDetector(
            onTap: widget.onLogin,
            child: RichText(
              text: TextSpan(
                style: context.textStyles.bodySmall
                    .copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Sign in',
                    style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ── Parent hero card ──────────────────────────────────────────────────────────
class _ParentHeroCard extends StatelessWidget {
  const _ParentHeroCard({
    required this.isDark,
    required this.cs,
    required this.onTap,
  });
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.coralButton,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.family_restroom_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Join as Parent',
                          style: GoogleFonts.lexend(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Enroll your child & track their day',
                          style: context.textStyles.bodySmall
                              .copyWith(color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact role card (Teacher / Admin) ───────────────────────────────────────
class _CompactRoleCard extends StatelessWidget {
  const _CompactRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? context.colors.bgDarkSurface : context.colors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 17, color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: context.textStyles.bodySmall
                            .copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.3), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Account details form
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Login details form
// ─────────────────────────────────────────────────────────────────────────────
class _LoginStep extends StatelessWidget {
  const _LoginStep({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.isDark,
    required this.cs,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl, confirmCtrl;
  final bool obscurePass, obscureConfirm, isDark;
  final VoidCallback onTogglePass, onToggleConfirm, onNext;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('Create login',
              style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Enter your email and a secure password',
              style: AppTextStyles.bodyMuted
                  .copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: AppSpacing.lg),

          // ── Email
          AuthTextField(
              label: 'Email Address',
              hint: 'jane@example.com',
              controller: emailCtrl,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              }),

          // ── Password
          _PassField(
              label: 'Password',
              hint: '8+ characters',
              ctrl: passCtrl,
              obscure: obscurePass,
              toggle: onTogglePass,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Min 8 characters';
                return null;
              }),
          _PassField(
              label: 'Confirm Password',
              hint: 'Re-enter password',
              ctrl: confirmCtrl,
              obscure: obscureConfirm,
              toggle: onToggleConfirm,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != passCtrl.text) return "Passwords don't match";
                return null;
              }),

          const SizedBox(height: AppSpacing.lg),
          AuthGradientButton(
            label: 'Next: Personal info',
            icon: Icons.arrow_forward_rounded,
            onTap: onNext,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — Profile/Parent details form
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileStep extends StatefulWidget {
  const _ProfileStep({
    required this.formKey,
    required this.role,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.referralCtrl,
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
    required this.relationCtrl,
    required this.staffIdCtrl,
    required this.designationCtrl,
    required this.centerNameCtrl,
    required this.adminDesigCtrl,
    required this.isDark,
    required this.cs,
    required this.loading,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final String role;
  final TextEditingController nameCtrl, phoneCtrl,
      referralCtrl, emergencyNameCtrl, emergencyPhoneCtrl,
      relationCtrl, staffIdCtrl, designationCtrl, centerNameCtrl, adminDesigCtrl;
  final bool isDark, loading;
  final VoidCallback onNext;
  final ColorScheme cs;

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  // Dropdown selections (stored as lowercase for DB consistency)
  String _relation = 'mother';
  bool _relationOther = false;

  String _teacherDesig = 'lead teacher';
  bool _teacherDesigOther = false;

  String _adminDesig = 'center director';
  bool _adminDesigOther = false;

  // Phone digits only (prefix +91 is locked)
  final _phoneDigitsCtrl = TextEditingController();
  final _emergencyPhoneDigitsCtrl = TextEditingController();

  static const _relationOptions = [
    'mother', 'father', 'guardian', 'grandmother',
    'grandfather', 'uncle', 'aunt', 'other',
  ];
  static const _teacherDesigOptions = [
    'lead teacher', 'assistant teacher', 'substitute teacher',
    'special educator', 'coordinator', 'other',
  ];
  static const _adminDesigOptions = [
    'center director', 'manager', 'owner', 'administrator', 'other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill digits if controller already has a value (e.g. back navigation)
    final existing = widget.phoneCtrl.text;
    if (existing.startsWith('+91')) {
      _phoneDigitsCtrl.text = existing.substring(3);
    }
    final existingEmg = widget.emergencyPhoneCtrl.text;
    if (existingEmg.startsWith('+91')) {
      _emergencyPhoneDigitsCtrl.text = existingEmg.substring(3);
    }
    // Sync digits → controller whenever digits change
    _phoneDigitsCtrl.addListener(_syncPhone);
    _emergencyPhoneDigitsCtrl.addListener(_syncEmergencyPhone);
    // Sync dropdown defaults to controllers
    _syncRelation(_relation);
    _syncTeacherDesig(_teacherDesig);
    _syncAdminDesig(_adminDesig);
  }

  void _syncPhone() {
    widget.phoneCtrl.text = '+91${_phoneDigitsCtrl.text.trim()}';
  }

  void _syncEmergencyPhone() {
    widget.emergencyPhoneCtrl.text = '+91${_emergencyPhoneDigitsCtrl.text.trim()}';
  }

  void _syncRelation(String v) => widget.relationCtrl.text = v;
  void _syncTeacherDesig(String v) => widget.designationCtrl.text = v;
  void _syncAdminDesig(String v) => widget.adminDesigCtrl.text = v;

  @override
  void dispose() {
    _phoneDigitsCtrl.removeListener(_syncPhone);
    _emergencyPhoneDigitsCtrl.removeListener(_syncEmergencyPhone);
    _phoneDigitsCtrl.dispose();
    _emergencyPhoneDigitsCtrl.dispose();
    super.dispose();
  }

  String? _req(String? v) => v == null || v.isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final isDark = widget.isDark;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('Your details',
              style: context.textStyles.heading2),
          const SizedBox(height: AppSpacing.xs),
          Text('Fill in your account information',
              style: context.textStyles.bodyMuted
                  .copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: AppSpacing.lg),

          // ── Full name
          AuthTextField(
              label: 'Full Name',
              hint: 'Jane Smith',
              controller: widget.nameCtrl,
              icon: Icons.person_outline_rounded,
              validator: _req),

          // ── Phone with locked +91 prefix
          _PhoneField(
            label: 'Phone Number',
            digitsCtrl: _phoneDigitsCtrl,
            isDark: isDark,
            cs: cs,
          ),

          // ── Referral code (teacher/admin only)
          if (widget.role != 'parent')
            AuthTextField(
                label: 'Referral Code',
                hint: 'TINY-XXXX  (from your admin)',
                controller: widget.referralCtrl,
                icon: Icons.vpn_key_outlined,
                validator: _req),

          // ── Parent-specific fields
          if (widget.role == 'parent') ...[
            const _Divider('Emergency contact'),
            AuthTextField(
                label: 'Contact Name',
                hint: 'John Smith',
                controller: widget.emergencyNameCtrl,
                icon: Icons.contact_emergency_outlined,
                validator: _req),
            _PhoneField(
              label: 'Contact Phone',
              digitsCtrl: _emergencyPhoneDigitsCtrl,
              isDark: isDark,
              cs: cs,
            ),
            // Relationship dropdown
            _DropdownField<String>(
              label: 'Relationship to Child',
              icon: Icons.people_outline_rounded,
              value: _relation,
              options: _relationOptions,
              displayLabel: (v) => _capitalise(v),
              isDark: isDark,
              cs: cs,
              onChanged: (v) {
                setState(() {
                  _relation = v!;
                  _relationOther = v == 'other';
                  if (!_relationOther) _syncRelation(v);
                });
              },
            ),
            if (_relationOther)
              AuthTextField(
                label: 'Specify relationship',
                hint: 'e.g. Step-parent, Sibling...',
                controller: widget.relationCtrl,
                icon: Icons.edit_outlined,
                validator: _req,
              ),
          ],

          // ── Teacher-specific fields
          if (widget.role == 'teacher') ...[
            const _Divider('Professional details'),
            AuthTextField(
                label: 'Staff ID',
                hint: 'EMP-1234 (optional)',
                controller: widget.staffIdCtrl,
                icon: Icons.badge_outlined),
            _DropdownField<String>(
              label: 'Designation',
              icon: Icons.work_outline_rounded,
              value: _teacherDesig,
              options: _teacherDesigOptions,
              displayLabel: (v) => _capitalise(v),
              isDark: isDark,
              cs: cs,
              onChanged: (v) {
                setState(() {
                  _teacherDesig = v!;
                  _teacherDesigOther = v == 'other';
                  if (!_teacherDesigOther) _syncTeacherDesig(v);
                });
              },
            ),
            if (_teacherDesigOther)
              AuthTextField(
                label: 'Specify designation',
                hint: 'e.g. Therapist, Nurse...',
                controller: widget.designationCtrl,
                icon: Icons.edit_outlined,
                validator: _req,
              ),
          ],

          // ── Admin-specific fields
          if (widget.role == 'admin') ...[
            const _Divider('Center details'),
            AuthTextField(
                label: 'Center Name',
                hint: 'Little Stars Daycare',
                controller: widget.centerNameCtrl,
                icon: Icons.business_outlined,
                validator: _req),
            _DropdownField<String>(
              label: 'Your Designation',
              icon: Icons.manage_accounts_outlined,
              value: _adminDesig,
              options: _adminDesigOptions,
              displayLabel: (v) => _capitalise(v),
              isDark: isDark,
              cs: cs,
              onChanged: (v) {
                setState(() {
                  _adminDesig = v!;
                  _adminDesigOther = v == 'other';
                  if (!_adminDesigOther) _syncAdminDesig(v);
                });
              },
            ),
            if (_adminDesigOther)
              AuthTextField(
                label: 'Specify designation',
                hint: 'e.g. Co-founder, Supervisor...',
                controller: widget.adminDesigCtrl,
                icon: Icons.edit_outlined,
                validator: _req,
              ),
          ],

          const SizedBox(height: AppSpacing.lg),
          AuthGradientButton(
            label: widget.role == 'parent'
                ? 'Next: Add child info'
                : 'Create account',
            icon: widget.role == 'parent'
                ? Icons.arrow_forward_rounded
                : Icons.check_rounded,
            onTap: widget.loading ? null : widget.onNext,
            loading: widget.loading,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  String _capitalise(String v) {
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1);
  }
}

// ── Locked +91 phone field ─────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.label,
    required this.digitsCtrl,
    required this.isDark,
    required this.cs,
  });
  final String label;
  final TextEditingController digitsCtrl;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: context.textStyles.labelBold.copyWith(color: cs.onSurface)),
          const SizedBox(height: 6),
          Row(
            children: [
              // Locked prefix badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: isDark ? context.colors.bgDarkMuted : context.colors.bgLight,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.md)),
                  border: Border.all(
                      color: cs.outline.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text('+91',
                        style: context.textStyles.labelBold
                            .copyWith(color: cs.onSurface)),
                  ],
                ),
              ),
              // Digits field
              Expanded(
                child: TextFormField(
                  controller: digitsCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: context.textStyles.bodyMedium
                      .copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '98765 43210',
                    hintStyle: context.textStyles.bodyMuted
                        .copyWith(color: cs.onSurface.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: isDark
                        ? context.colors.bgDarkMuted
                        : context.colors.bgLight,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.md)),
                      borderSide: BorderSide(
                          color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.md)),
                      borderSide: BorderSide(
                          color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.md)),
                      borderSide: BorderSide(
                          color: context.colors.primary, width: 1.8),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.md)),
                      borderSide: BorderSide(
                          color: context.colors.danger),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.md)),
                      borderSide: BorderSide(
                          color: context.colors.danger, width: 1.8),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.replaceAll(RegExp(r'\D'), '').length != 10) {
                      return 'Enter 10 digits';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Generic themed dropdown ────────────────────────────────────────────────
class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.displayLabel,
    required this.isDark,
    required this.cs,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final T value;
  final List<T> options;
  final String Function(T) displayLabel;
  final bool isDark;
  final ColorScheme cs;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: context.textStyles.labelBold.copyWith(color: cs.onSurface)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? context.colors.bgDarkMuted : context.colors.bgLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border:
                  Border.all(color: cs.outline.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<T>(
                      value: value,
                      isExpanded: true,
                      dropdownColor: isDark
                          ? context.colors.bgDarkSurface
                          : context.colors.bgSurface,
                      style: context.textStyles.bodyMedium
                          .copyWith(color: cs.onSurface),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      items: options.map((o) {
                        return DropdownMenuItem<T>(
                          value: o,
                          child: Text(displayLabel(o)),
                        );
                      }).toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — First child info (parents only)
// ─────────────────────────────────────────────────────────────────────────────
class _ChildInfoStep extends StatelessWidget {
  const _ChildInfoStep({
    required this.formKey,
    required this.childNameCtrl,
    required this.childDob,
    required this.childGender,
    required this.allergyCtrl,
    required this.medCtrl,
    required this.classroomCodeCtrl,
    required this.isDark,
    required this.cs,
    required this.loading,
    required this.onPickDob,
    required this.onGenderChange,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController childNameCtrl, allergyCtrl, medCtrl, classroomCodeCtrl;
  final DateTime? childDob;
  final String childGender;
  final bool isDark, loading;
  final ColorScheme cs;
  final VoidCallback onPickDob, onSubmit;
  final void Function(String?) onGenderChange;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),

          // Header with coral accent icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.child_care_rounded,
                    color: context.colors.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your child's info",
                        style: context.textStyles.heading2),
                    Text("You can add more children after sign-up",
                        style: context.textStyles.bodySmall.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          AuthTextField(
            label: "Child's Full Name",
            hint: 'Emma Smith',
            controller: childNameCtrl,
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
          ),

          // Date of birth picker
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date of Birth", style: context.textStyles.labelBold
                    .copyWith(color: cs.onSurface)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onPickDob,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 15),
                    decoration: BoxDecoration(
                      color: isDark ? context.colors.bgDarkMuted : context.colors.bgLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 12),
                        Text(
                          childDob != null
                              ? '${childDob!.day}/${childDob!.month}/${childDob!.year}'
                              : 'Select date of birth',
                          style: childDob != null
                              ? context.textStyles.bodyMedium
                                  .copyWith(color: cs.onSurface)
                              : context.textStyles.bodyMuted.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.35)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Gender
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gender', style: context.textStyles.labelBold
                    .copyWith(color: cs.onSurface)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color:
                        isDark ? context.colors.bgDarkMuted : context.colors.bgLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: cs.outline.withValues(alpha: 0.4)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: childGender,
                      isExpanded: true,
                      dropdownColor: isDark
                          ? context.colors.bgDarkSurface
                          : context.colors.bgSurface,
                      style: context.textStyles.bodyMedium
                          .copyWith(color: cs.onSurface),
                      items: const [
                        DropdownMenuItem(
                            value: 'male',
                            child: Text('Male')),
                        DropdownMenuItem(
                            value: 'female',
                            child: Text('Female')),
                        DropdownMenuItem(
                            value: 'other',
                            child: Text('Prefer not to say')),
                      ],
                      onChanged: onGenderChange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          AuthTextField(
              label: 'Allergies',
              hint: 'None / Peanuts / Dairy... (optional)',
              controller: allergyCtrl,
              icon: Icons.warning_amber_outlined),
          AuthTextField(
              label: 'Medical Notes',
              hint: 'Any conditions the teacher should know (optional)',
              controller: medCtrl,
              icon: Icons.medical_information_outlined),

          // Classroom code (optional — admin gives this on admission)
          const _Divider('Classroom assignment'),
          AuthTextField(
            label: 'Classroom Code',
            hint: 'e.g. BLUE-A (from admin, optional)',
            controller: classroomCodeCtrl,
            icon: Icons.meeting_room_outlined,
          ),
          // Note about classroom code
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14,
                    color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Leave empty if you don\'t have a code yet — admin can assign your child to a classroom later.',
                    style: context.textStyles.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Info note
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: context.colors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'This info is visible to your child\'s assigned teacher and the center admin. You can update it anytime from your profile.',
                    style: context.textStyles.bodySmall.copyWith(
                        color: context.colors.primary.withValues(alpha: 0.85)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          AuthGradientButton(
            label: 'Create account',
            icon: Icons.check_rounded,
            onTap: loading ? null : onSubmit,
            loading: loading,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _PassField extends StatelessWidget {
  const _PassField({
    required this.label,
    required this.hint,
    required this.ctrl,
    required this.obscure,
    required this.toggle,
    this.validator,
  });
  final String label, hint;
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback toggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AuthTextField(
      label: label,
      hint: hint,
      controller: ctrl,
      icon: Icons.lock_outline_rounded,
      obscureText: obscure,
      validator: validator,
      suffix: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: cs.onSurface.withValues(alpha: 0.4),
        ),
        onPressed: toggle,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
          top: AppSpacing.md, bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: cs.outline.withValues(alpha: 0.4), height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(label,
                style: context.textStyles.labelMedium
                    .copyWith(color: cs.onSurface.withValues(alpha: 0.45))),
          ),
          Expanded(
              child: Divider(color: cs.outline.withValues(alpha: 0.4), height: 1)),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i < current;
        final dot = i + 1;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? context.colors.primary : context.colors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (dot < total) const SizedBox(width: 4),
          ],
        );
      }),
    );
  }
}
