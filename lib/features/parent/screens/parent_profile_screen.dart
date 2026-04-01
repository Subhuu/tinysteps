import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/widgets/logout_dialog.dart'; // ✅ ADD THIS

/// Parent Profile (Account) Screen
class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Account', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Builder(builder: (context) {
                final user = Supabase.instance.client.auth.currentUser;
                final name = user?.userMetadata?['full_name'] as String? ?? 'Parent';
                final email = user?.email ?? '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.heading2),
                          const SizedBox(height: 2),
                          Text(email, style: AppTextStyles.bodyMuted),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),

            // 2. Settings List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                        icon: Icons.person_outline,
                        title: 'Personal Details',
                        onTap: () => context.push('/parent/account/personal')),
                    const Divider(height: 1, color: AppColors.border),
                    _buildSettingsTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Pickup Authorization',
                        onTap: () => context.push('/parent/account/pickup')),
                    const Divider(height: 1, color: AppColors.border),
                    _buildSettingsTile(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        onTap: () => context.push('/parent/account/notifications')),
                    const Divider(height: 1, color: AppColors.border),
                    _buildSettingsTile(
                        icon: Icons.payment_outlined,
                        title: 'Payments',
                        onTap: () => context.push('/parent/account/payments')),
                    const Divider(height: 1, color: AppColors.border),
                    _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'Support & Help',
                        onTap: () => context.push('/parent/account/support')),
                    const Divider(height: 1, color: AppColors.border),
                    _buildSettingsTile(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () => context.push('/parent/account/settings')),
                    const Divider(height: 1, color: AppColors.border),
                    _buildSettingsTile(
                        icon: Icons.info_outline,
                        title: 'About App',
                        onTap: () => context.push('/parent/account/about')),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 3. Logout Button (✅ FIXED)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showLogoutDialog(context); // ✅ dialog
                    if (confirmed) {
                      await Supabase.instance.client.auth.signOut();
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  label: Text(
                    'Log Out',
                    style: AppTextStyles.buttonLabel.copyWith(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Icon(icon, color: AppColors.textMedium, size: 28),
      ),
      title: Text(title, style: AppTextStyles.labelBold),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(subtitle, style: AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}