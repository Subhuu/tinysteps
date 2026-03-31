import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class MyChildrenScreen extends StatelessWidget {
  const MyChildrenScreen({super.key});

  // Placeholder children — intern will replace with Supabase data
  static const _placeholderChildren = [
    {'id': 'child-001', 'name': 'Leo Smith', 'dob': '12 Apr 2021', 'classroom': 'Sunshine Room'},
    {'id': 'child-002', 'name': 'Mia Smith', 'dob': '03 Aug 2022', 'classroom': 'Rainbow Room'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('My Children', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: _placeholderChildren.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _placeholderChildren.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final child = _placeholderChildren[index];
                return _ChildCard(
                  childId: child['id']!,
                  name: child['name']!,
                  dob: child['dob']!,
                  classroom: child['classroom']!,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/parent/children/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.child_care_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text('No children added yet', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text('Tap the + button to add your child', style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final String childId;
  final String name;
  final String dob;
  final String classroom;

  const _ChildCard({
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
                name[0].toUpperCase(),
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
