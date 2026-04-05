import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Shared across all roles — Help Center, call daycare, email, FAQ.
/// Navigate here via context.push('/support') from any settings screen.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Help & Support', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How can we help?', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reach out to the daycare team through any of the options below.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),

            _SupportCard(
              icon: Icons.phone_outlined,
              title: 'Call Daycare',
              subtitle: '+91 98765 43210',
              color: AppColors.success,
              onTap: () {
                // TODO: launch phone URL using url_launcher
              },
            ),
            const SizedBox(height: AppSpacing.md),

            _SupportCard(
              icon: Icons.mail_outline_rounded,
              title: 'Email Support',
              subtitle: 'support@tinysteps.in',
              color: AppColors.primary,
              onTap: () {
                // TODO: launch mailto URL using url_launcher
              },
            ),
            const SizedBox(height: AppSpacing.md),

            _SupportCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'WhatsApp',
              subtitle: 'Message us on WhatsApp',
              color: AppColors.success,
              onTap: () {
                // TODO: launch whatsapp link
              },
            ),
            const SizedBox(height: AppSpacing.md),

            _SupportCard(
              icon: Icons.help_outline_rounded,
              title: 'FAQs',
              subtitle: 'Answers to common questions',
              color: AppColors.secondary,
              onTap: () {
                // TODO: open FAQ page or accordion here
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Office hours info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Office Hours',
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text('Mon – Sat: 8:00 AM – 6:00 PM',
                            style: AppTextStyles.bodySmall),
                        Text('Sunday: Closed',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
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
          color: AppColors.white,
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
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
