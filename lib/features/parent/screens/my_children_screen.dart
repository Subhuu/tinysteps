import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/features/parent/widgets/child_card.dart';

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
    _childrenFuture = _supabase
        .from('children')
        .select('id, full_name, date_of_birth, classrooms(name)')
        .eq('parent_id', uid)
        .order('created_at');
  }

  // Format date natively
  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoString;
    }
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
      body: FutureBuilder<List<dynamic>>(
        future: _childrenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Error loading children:\n${snapshot.error}',
                  style: AppTextStyles.bodyMuted.copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final children = snapshot.data ?? [];

          if (children.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => setState(() => _loadChildren()),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final child = children[index] as Map<String, dynamic>;
                
                final classroomData = child['classrooms'] as Map<String, dynamic>?;
                final classroomName = classroomData != null ? classroomData['name'] as String : 'Not Assigned';
                
                return ChildCard(
                  childId: child['id'] as String,
                  name: child['full_name'] as String? ?? 'Unknown',
                  dob: _formatDate(child['date_of_birth'] as String? ?? ''),
                  classroom: classroomName,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await context.push('/parent/children/add');
          if (added == true && mounted) {
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
}
