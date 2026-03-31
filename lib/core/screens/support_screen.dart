import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Shared across all roles — contact daycare, FAQ, email support.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Support & Help', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How can we help?', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text('Reach out to the daycare team through the options below.', style: AppTextStyles.bodyMuted),
            const SizedBox(height: AppSpacing.xl),

            _SupportCard(
              icon: Icons.phone_outlined,
              title: 'Call Daycare',
              subtitle: '+91 98765 43210',
              color: AppColors.success,
              onTap: () {/* TODO: launch phone url */},
            ),
            const SizedBox(height: AppSpacing.md),
            _SupportCard(
              icon: Icons.mail_outline,
              title: 'Email Support',
              subtitle: 'support@tinysteps.in',
              color: AppColors.primary,
              onTap: () {/* TODO: launch mailto url */},
            ),
            const SizedBox(height: AppSpacing.md),
            _SupportCard(
              icon: Icons.help_outline,
              title: 'FAQs',
              subtitle: 'Find answers to common questions',
              color: AppColors.secondary,
              onTap: () {/* TODO: open FAQ page */},
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelBold),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
