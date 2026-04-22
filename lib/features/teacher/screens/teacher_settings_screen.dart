import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/widgets/logout_dialog.dart';

/// Teacher Settings Screen — profile + preferences + account
class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Profile data from DB
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _staffId = '';
  String _designation = '';
  String _joiningDate = '';
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final data = await _supabase
          .from('teachers')
          .select('full_name, email, phone, staff_id, designation, joining_date, is_approved')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _fullName = data['full_name'] as String? ?? '';
          _email = data['email'] as String? ?? _supabase.auth.currentUser?.email ?? '';
          _phone = data['phone'] as String? ?? '';
          _staffId = data['staff_id'] as String? ?? '';
          _designation = data['designation'] as String? ?? 'Teacher';
          _joiningDate = data['joining_date'] as String? ?? '';
          _isApproved = data['is_approved'] == true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _email = _supabase.auth.currentUser?.email ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _fullName);
    final phoneCtrl = TextEditingController(text: _phone);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Edit Profile', style: AppTextStyles.heading3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField(nameCtrl, 'Full Name', Icons.person_outline),
              const SizedBox(height: AppSpacing.sm),
              _inputField(phoneCtrl, 'Phone', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.labelBold.copyWith(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
            ),
            onPressed: () async {
              final uid = _supabase.auth.currentUser?.id;
              if (uid == null) return;
              await _supabase.from('teachers').update({
                'full_name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
              }).eq('id', uid);
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadProfile();
            },
            child: Text('Save', style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'T';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : CustomScrollView(
              slivers: [
                // ── Lavender Gradient Profile Header ───────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppGradients.lavenderAccent,
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(AppRadius.xl)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('Settings',
                                    style: AppTextStyles.heading2
                                        .copyWith(color: AppColors.white)),
                                const Spacer(),
                                IconButton(
                                  onPressed: _showEditProfileDialog,
                                  icon: Container(
                                    padding: const EdgeInsets.all(AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: AppColors.white
                                          .withValues(alpha: 0.25),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const Icon(Icons.edit_outlined,
                                        color: AppColors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.white
                                            .withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.white, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initial,
                                          style: AppTextStyles.heading1
                                              .copyWith(color: AppColors.white),
                                        ),
                                      ),
                                    ),
                                    // Approval badge
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: _isApproved
                                              ? AppColors.success
                                              : AppColors.warning,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.white, width: 2),
                                        ),
                                        child: Icon(
                                          _isApproved
                                              ? Icons.check
                                              : Icons.hourglass_top_rounded,
                                          color: AppColors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _fullName.isNotEmpty
                                            ? _fullName
                                            : 'Teacher',
                                        style: AppTextStyles.heading3
                                            .copyWith(color: AppColors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _email,
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.white
                                                .withValues(alpha: 0.85)),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      _roleBadge(
                                        _isApproved
                                            ? (_designation.isNotEmpty
                                                ? _designation
                                                : 'Teacher')
                                            : 'Pending Approval',
                                        _isApproved
                                            ? AppColors.white
                                            : AppColors.warning,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Body ────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Profile details card
                      _infoCard(children: [
                        if (_phone.isNotEmpty) ...[
                          _infoRow(Icons.phone_outlined, 'Phone', _phone),
                          const Divider(
                              height: AppSpacing.lg, color: AppColors.border),
                        ],
                        if (_staffId.isNotEmpty) ...[
                          _infoRow(Icons.numbers, 'Staff ID', _staffId),
                          const Divider(
                              height: AppSpacing.lg, color: AppColors.border),
                        ],
                        if (_joiningDate.isNotEmpty)
                          _infoRow(Icons.calendar_today_outlined, 'Joined',
                              _joiningDate),
                        if (_phone.isEmpty &&
                            _staffId.isEmpty &&
                            _joiningDate.isEmpty)
                          _infoRow(Icons.info_outline, 'Profile',
                              'Tap edit to update your profile'),
                      ]),
                      const SizedBox(height: AppSpacing.lg),

                      // ── App Preferences ─────────────────────────────
                      _sectionLabel('Preferences'),
                      _settingsTile(
                        icon: Icons.notifications_none_rounded,
                        iconColor: AppColors.accent,
                        title: 'Push Notifications',
                        subtitle: 'Attendance alerts & messages',
                        onTap: () => context.push('/notifications'),
                      ),
                      _settingsTile(
                        icon: Icons.settings_outlined,
                        iconColor: AppColors.info,
                        title: 'App Settings',
                        subtitle: 'Appearance and language',
                        onTap: () => context.push('/app-settings'),
                      ),

                      // ── Support ──────────────────────────────────────
                      _sectionLabel('Support & Legal'),
                      _settingsTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: AppColors.secondary,
                        title: 'Help Center',
                        onTap: () => context.push('/support'),
                      ),
                      _settingsTile(
                        icon: Icons.description_outlined,
                        iconColor: AppColors.textMuted,
                        title: 'Privacy Policy',
                        onTap: () => context.push('/privacy-policy'),
                      ),
                      _settingsTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.textMuted,
                        title: 'About TinySteps',
                        subtitle: 'Version info & credits',
                        onTap: () => context.push('/about'),
                      ),

                      // ── Account ──────────────────────────────────────
                      _sectionLabel('Account'),
                      _settingsTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.warning,
                        title: 'Change Password',
                        onTap: () => context.push('/change-password'),
                      ),
                      _dangerTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        onTap: () async {
                          final ok = await showLogoutDialog(context);
                          if (ok) await _supabase.auth.signOut();
                        },
                      ),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 16),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.labelBold),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted))
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _dangerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.danger, size: 20),
        ),
        title: Text(title,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.danger)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.danger, size: 20),
        onTap: onTap,
      ),
    );
  }
}
