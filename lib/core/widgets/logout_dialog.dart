import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Shows a styled logout confirmation dialog.
/// Returns [true] if the user confirmed, [false] if they cancelled.
Future<bool> showLogoutDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgLight,
          surfaceTintColor: Colors.transparent,
          title: Text('Sign out?', style: AppTextStyles.heading3),
          content: Text(
            'You will be returned to the login screen.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sign out', style: AppTextStyles.buttonLabel),
            ),
          ],
        ),
      ) ??
      false;
}
