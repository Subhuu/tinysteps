import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class MyChildrenScreen extends StatefulWidget {
  const MyChildrenScreen({super.key});

  @override
  State<MyChildrenScreen> createState() => _MyChildrenScreenState();
}

class _MyChildrenScreenState extends State<MyChildrenScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<dynamic>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  void _loadChildren() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      _childrenFuture = Future.value([]);
      return;
    }
    // Fetch children for current parent — same source as parent_home_screen
    // Also join classrooms table to get classroom name
    _childrenFuture = _supabase
        .from('children')
        .select('id, full_name, date_of_birth, status, classrooms(name)')
        .eq('parent_id', uid)
        .order('full_name');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('My Children', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => setState(() => _loadChildren()),
        child: FutureBuilder<List<dynamic>>(
          future: _childrenFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Failed to load children.\nPlease pull down to retry.',
                    style: AppTextStyles.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final children = snapshot.data ?? [];

            if (children.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final child = children[index] as Map<String, dynamic>;
                final childId = child['id'] as String;
                final name = child['full_name'] as String? ?? 'Child';
                final dob = child['date_of_birth'] as String? ?? '';
                final classroom = child['classrooms'] as Map<String, dynamic>?;
                final classroomName = classroom?['name'] as String? ?? 'Unassigned';

                // Format DOB from ISO (yyyy-MM-dd) to readable form
                String formattedDob = dob;
                if (dob.isNotEmpty) {
                  try {
                    final date = DateTime.parse(dob);
                    formattedDob = '${date.day} ${_monthName(date.month)} ${date.year}';
                  } catch (_) {
                    // keep raw value
                  }
                }

                return _ChildCard(
                  childId: childId,
                  name: name,
                  dob: formattedDob,
                  classroom: classroomName,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/parent/children/add');
          // Refresh list if a child was added
          if (result == true && mounted) {
            setState(() => _loadChildren());
          }
        },
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

  String _monthName(int month) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month];
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
