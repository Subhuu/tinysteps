import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Shared across all roles — shows app version, credits, etc.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('About App', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Logo / brand
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppGradients.coralButton,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.button,
              ),
              child: const Icon(Icons.child_care_rounded, color: AppColors.white, size: 48),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('TinySteps', style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.xs),
            Text('DayCare+', style: AppTextStyles.bodyMuted),
            const SizedBox(height: AppSpacing.sm),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text('Version 1.0.0 (MVP)', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: AppSpacing.xxl),

            _InfoTile(icon: Icons.info_outline, title: 'Built by', value: 'TinySteps Internship Team – 2026'),
            const Divider(height: 1, color: AppColors.divider),
            _InfoTile(icon: Icons.code, title: 'Stack', value: 'Flutter + Supabase'),
            const Divider(height: 1, color: AppColors.divider),
            _InfoTile(icon: Icons.mail_outline, title: 'Support', value: 'support@tinysteps.in'),
            const Divider(height: 1, color: AppColors.divider),
            _InfoTile(icon: Icons.gavel_outlined, title: 'Terms & Privacy', value: 'tinysteps.in/legal'),

            const SizedBox(height: AppSpacing.xxl),
            Text('© 2026 TinySteps. All rights reserved.', style: AppTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Text(title, style: AppTextStyles.labelBold),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}
