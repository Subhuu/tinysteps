import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class PickupAuthorizationScreen extends StatelessWidget {
  const PickupAuthorizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Pickup Authorization', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Authorized Persons', style: AppTextStyles.heading3),
            Text(
              'These people are allowed to pick up your children from the daycare.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Empty state
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_off_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: AppSpacing.md),
                  Text('No authorized persons added', style: AppTextStyles.bodyMuted),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Add someone trusted to pick up your children', style: AppTextStyles.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Show add authorized person dialog
                },
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: Text('Add Authorized Person', style: AppTextStyles.labelBold.copyWith(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
