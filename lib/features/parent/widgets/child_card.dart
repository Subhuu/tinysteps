import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class ChildCard extends StatelessWidget {
  final String childId;
  final String name;
  final String dob;
  final String classroom;

  const ChildCard({
    super.key,
    required this.childId,
    required this.name,
    required this.dob,
    required this.classroom,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/parent/children/$childId?name=${Uri.encodeComponent(name)}'),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelBold),
                  const SizedBox(height: 2),
                  Text('DOB: $dob', style: AppTextStyles.bodyMuted),
                  Text(classroom, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
