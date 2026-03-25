import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.inbox_outlined,
          size: 48,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }
}
