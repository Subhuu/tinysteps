import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Parent';
    final firstName = name.split(' ').first;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.colors.primaryLight,
              child: Text(
                initial,
                style: context.textStyles.labelBold.copyWith(color: context.colors.primary, fontSize: 14),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              firstName,
              style: context.textStyles.heading2.copyWith(color: context.colors.textDark),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            color: context.colors.textDark,
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('Growth & Nutrition', style: context.textStyles.heading1),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Monitoring Liam\'s daily and weekly intake',
              style: context.textStyles.bodyMedium.copyWith(color: context.colors.textMuted),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Coming soon...',
                style: context.textStyles.bodyLarge.copyWith(color: context.colors.textMuted),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
