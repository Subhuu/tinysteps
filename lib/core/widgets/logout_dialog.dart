import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

Future<bool> showLogoutDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgLight,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Confirm Logout',
        style: AppTextStyles.heading3,
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: AppTextStyles.labelBold.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Logout',
            style: AppTextStyles.buttonLabel,
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}