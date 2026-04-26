import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

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
          color: context.colors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: context.colors.primary.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: context.textStyles.labelBold),
                  const SizedBox(height: 2),
                  Text('DOB: $dob', style: context.textStyles.bodyMuted),
                  Text(classroom, style: context.textStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}
