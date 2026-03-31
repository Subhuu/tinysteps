import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Admin Children Overview — all enrolled children with classroom + teacher info
class ChildrenOverviewScreen extends StatefulWidget {
  const ChildrenOverviewScreen({super.key});

  @override
  State<ChildrenOverviewScreen> createState() => _ChildrenOverviewScreenState();
}

class _ChildrenOverviewScreenState extends State<ChildrenOverviewScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<dynamic>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // Single projected query with embedded classroom + parent names
    _childrenFuture = _supabase
        .from('children')
        .select(
            'id, full_name, date_of_birth, gender, status, classroom_id, teacher_id, '
            'classrooms(name, code), parents!inner(full_name)')
        .order('full_name');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('All Children', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => setState(() => _load()),
        child: FutureBuilder<List<dynamic>>(
          future: _childrenFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load children\n${snapshot.error}',
                    style: AppTextStyles.bodyMuted,
                    textAlign: TextAlign.center),
              );
            }
            final children = snapshot.data ?? [];
            if (children.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care_outlined,
                        size: 64,
                        color: AppColors.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('No children enrolled', style: AppTextStyles.heading3),
                  ],
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final c = children[index] as Map<String, dynamic>;
                final classroom = c['classrooms'] as Map<String, dynamic>?;
                final parent = c['parents'] as Map<String, dynamic>?;
                final status = c['status'] as String? ?? 'active';

                final classroomLabel = classroom != null
                    ? '${classroom['name']} (${classroom['code']})'
                    : 'Unassigned';
                final parentName =
                    parent?['full_name'] as String? ?? 'Unknown';

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: classroom != null
                            ? AppColors.primaryLight
                            : AppColors.warning.withValues(alpha: 0.15),
                        child: Text(
                          (c['full_name'] as String? ?? 'C')[0].toUpperCase(),
                          style: AppTextStyles.labelBold.copyWith(
                            color: classroom != null
                                ? AppColors.primary
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['full_name'] ?? '—',
                                style: AppTextStyles.labelBold),
                            Text(
                              'Parent: $parentName',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              'Classroom: $classroomLabel',
                              style: AppTextStyles.caption.copyWith(
                                color: classroom != null
                                    ? AppColors.textMuted
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        label: _statusLabel(status),
                        color: _statusColor(status),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'active' => 'Active',
        'withdrawn' => 'Withdrawn',
        'waitlisted' => 'Waitlisted',
        'graduated' => 'Graduated',
        _ => s,
      };

  Color _statusColor(String s) => switch (s) {
        'active' => AppColors.success,
        'withdrawn' => AppColors.danger,
        'waitlisted' => AppColors.warning,
        'graduated' => AppColors.secondary,
        _ => AppColors.textMuted,
      };
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
