import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

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
        .select('id, full_name, date_of_birth, gender, allergies, status, classrooms(name)')
        .eq('parent_id', uid)
        .order('full_name');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('My Children', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async => setState(() => _loadChildren()),
        child: FutureBuilder<List<dynamic>>(
          future: _childrenFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(color: context.colors.primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Failed to load children.\nPlease pull down to retry.',
                    style: context.textStyles.bodyMuted,
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
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final child = children[index] as Map<String, dynamic>;
                final childId = child['id'] as String;
                final name = child['full_name'] as String? ?? 'Child';
                final dob = child['date_of_birth'] as String? ?? '';
                final allergies = child['allergies'] as String? ?? '';
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
                  hasAllergies: allergies.isNotEmpty,
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
        backgroundColor: context.colors.primary,
        child: Icon(Icons.add, color: context.colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.child_care_rounded, size: 64, color: context.colors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text('No children added yet', style: context.textStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text('Tap the + button to add your child', style: context.textStyles.bodyMuted),
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
  final bool hasAllergies;

  const _ChildCard({
    required this.childId,
    required this.name,
    required this.dob,
    required this.classroom,
    this.hasAllergies = false,
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
                name[0].toUpperCase(),
                style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(name, style: context.textStyles.labelBold)),
                      if (hasAllergies) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 10, color: context.colors.warning),
                              const SizedBox(width: 3),
                              Text('Allergy',
                                  style: context.textStyles.caption.copyWith(
                                      color: context.colors.warning,
                                      fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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
