import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tinysteps/core/constants/app_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  // Cached futures — fetched once per tab view
  late Future<List<dynamic>> _teachersFuture;
  late Future<List<dynamic>> _parentsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  void _refresh() {
    _teachersFuture = _supabase
        .from('teachers')
        .select('id, full_name, email, staff_id, designation, is_approved, is_active, classrooms!classrooms_teacher_id_fkey(id, name)')
        .order('full_name');

    // FIX: Use correct FK hint for the children → parents relationship
    _parentsFuture = _supabase
        .from('parents')
        .select(
          'id, full_name, phone, emergency_contact_name, emergency_contact_phone, '
          'relationship_to_child, is_active, children!children_parent_id_fkey(id)',
        )
        .order('full_name');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Users Management', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTextStyles.labelBold,
          unselectedLabelStyle: AppTextStyles.labelMedium,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Teachers'),
            Tab(text: 'Parents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeachersTab(),
          _buildParentsTab(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TEACHERS TAB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTeachersTab() {
    return FutureBuilder<List<dynamic>>(
      future: _teachersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Failed to load teachers', style: AppTextStyles.bodyMuted),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    snapshot.error.toString(),
                    style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final teachers = snapshot.data ?? [];
        if (teachers.isEmpty) {
          return Center(
            child: Text('No teachers found', style: AppTextStyles.bodyMuted),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          itemCount: teachers.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final t = teachers[index] as Map<String, dynamic>;
            final isApproved = t['is_approved'] == true;
            final isActive = t['is_active'] == true;

            final String statusLabel;
            final Color statusColor;
            if (isApproved && isActive) {
              statusLabel = 'Active';
              statusColor = AppColors.success;
            } else if (!isApproved) {
              statusLabel = 'Pending';
              statusColor = AppColors.warning;
            } else {
              statusLabel = 'Inactive';
              statusColor = AppColors.danger;
            }

            return Card(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (t['full_name'] as String? ?? 'T')[0].toUpperCase(),
                    style: AppTextStyles.labelBold.copyWith(color: AppColors.primary),
                  ),
                ),
                title: Text(t['full_name'] ?? 'Unknown', style: AppTextStyles.labelBold),
                subtitle: Builder(builder: (_) {
                  final classroomsData = t['classrooms'] as List<dynamic>? ?? [];
                  final classroomName = classroomsData.isNotEmpty 
                      ? classroomsData.first['name'] as String 
                      : 'No Classroom';

                  final parts = <String>[
                    if (t['designation'] != null && (t['designation'] as String).isNotEmpty)
                      t['designation'] as String,
                    classroomName,
                  ];
                  return Text(
                    parts.isEmpty ? 'No details provided' : parts.join('  ·  '),
                    style: AppTextStyles.bodySmall,
                  );
                }),
                trailing: _StatusBadge(label: statusLabel, color: statusColor),
                onTap: () => _showTeacherDetail(context, t),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showTeacherDetail(
      BuildContext context, Map<String, dynamic> teacher) async {
    // Fetch classrooms for assignment picker — code may be null
    final classrooms = await _supabase
        .from('classrooms')
        .select('id, name, code')
        .order('name');

    if (!context.mounted) return;

    String? selectedClassroomId;
    final name = teacher['full_name'] as String? ?? 'Teacher';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    final staffId = teacher['staff_id'] as String?;
    final designation = teacher['designation'] as String?;
    final isApproved = teacher['is_approved'] == true;
    final isActive = teacher['is_active'] == true;
    
    final classroomsData = teacher['classrooms'] as List<dynamic>? ?? [];
    final currentClassroomName = classroomsData.isNotEmpty ? classroomsData.first['name'] as String : 'Not Assigned';
    selectedClassroomId = classroomsData.isNotEmpty ? classroomsData.first['id'] as String : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgLight,
          surfaceTintColor: Colors.transparent,
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Avatar + Name + Status ─────────────────────────────
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(name, style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    _StatusBadge(
                      label: isApproved ? 'Approved' : 'Pending',
                      color: isApproved ? AppColors.success : AppColors.warning,
                    ),
                    _StatusBadge(
                      label: isActive ? 'Active' : 'Inactive',
                      color: isActive ? AppColors.success : AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Info card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      if (designation != null && designation.isNotEmpty) ...[
                        _DetailRow(
                          icon: Icons.badge_outlined,
                          label: 'Designation',
                          value: designation,
                        ),
                        const Divider(height: AppSpacing.lg, color: AppColors.border),
                      ],
                      if (staffId != null && staffId.isNotEmpty) ...[
                        _DetailRow(
                          icon: Icons.numbers,
                          label: 'Staff ID',
                          value: staffId,
                        ),
                        const Divider(height: AppSpacing.lg, color: AppColors.border),
                      ],
                      _DetailRow(
                        icon: Icons.meeting_room_outlined,
                        label: 'Classroom',
                        value: currentClassroomName,
                      ),
                      const Divider(height: AppSpacing.lg, color: AppColors.border),
                      _DetailRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: teacher['email'] as String? ?? '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Approve / Revoke ───────────────────────────────────
                if (!isApproved)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                      ),
                      onPressed: () async {
                        await _supabase
                            .from('teachers')
                            .update({'is_approved': true, 'is_active': true})
                            .eq('id', teacher['id']);
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() => _refresh());
                      },
                      label: Text('Approve', style: AppTextStyles.buttonLabel),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                      ),
                      onPressed: () async {
                        await _supabase
                            .from('teachers')
                            .update({'is_approved': false})
                            .eq('id', teacher['id']);
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() => _refresh());
                      },
                      label: Text(
                        'Revoke Approval',
                        style: AppTextStyles.labelBold.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),

                // ── Activate / Deactivate ──────────────────────────────
                if (isApproved)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        isActive ? Icons.person_off_outlined : Icons.person_add_alt_1,
                        size: 18,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isActive ? AppColors.danger : AppColors.success,
                        side: BorderSide(color: isActive ? AppColors.danger : AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                      ),
                      onPressed: () async {
                        await _supabase
                            .from('teachers')
                            .update({'is_active': !isActive})
                            .eq('id', teacher['id']);
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() => _refresh());
                      },
                      label: Text(
                        isActive ? 'Deactivate' : 'Activate',
                        style: AppTextStyles.labelBold.copyWith(
                          color: isActive ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // ── Assign Classroom ───────────────────────────────────
                Text('Assign Classroom', style: AppTextStyles.labelBold),
                const SizedBox(height: AppSpacing.sm),
                if (classrooms.isEmpty)
                  Text('No classrooms available', style: AppTextStyles.bodyMuted)
                else
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.bgSurface,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.inputRadius,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.inputRadius,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    hint: Text('Select classroom', style: AppTextStyles.bodyMuted),
                    initialValue: selectedClassroomId,
                    items: classrooms.map((c) {
                      // FIX: code is nullable — fallback to name only
                      final code = c['code'] as String?;
                      final label = code != null && code.isNotEmpty
                          ? '${c['name']} ($code)'
                          : '${c['name']}';
                      return DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(label, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedClassroomId = val),
                  ),
                if (classrooms.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                      ),
                      onPressed: selectedClassroomId == null
                          ? null
                          : () async {
                              try {
                                // Update classroom teacher
                                await _supabase
                                    .from('classrooms')
                                    .update({'teacher_id': teacher['id']})
                                    .eq('id', selectedClassroomId!);
                                // Update children in that classroom
                                await _supabase
                                    .from('children')
                                    .update({'teacher_id': teacher['id']})
                                    .eq('classroom_id', selectedClassroomId!);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Classroom assigned successfully'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                                setState(() => _refresh());
                              } on PostgrestException catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.message}'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text('Confirm Assignment', style: AppTextStyles.buttonLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PARENTS TAB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildParentsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _parentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Failed to load parents', style: AppTextStyles.bodyMuted),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    snapshot.error.toString(),
                    style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final parents = snapshot.data ?? [];
        if (parents.isEmpty) {
          return Center(
            child: Text('No parents found', style: AppTextStyles.bodyMuted),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          itemCount: parents.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final p = parents[index] as Map<String, dynamic>;

            // FIX: children is now correctly fetched via FK hint
            final childrenData = p['children'] as List<dynamic>? ?? [];
            final childCount = childrenData.length;

            return Card(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondaryLight,
                  child: Text(
                    (p['full_name'] as String? ?? 'P')[0].toUpperCase(),
                    style: AppTextStyles.labelBold
                        .copyWith(color: AppColors.secondary),
                  ),
                ),
                title: Text(
                  p['full_name'] ?? 'Unknown',
                  style: AppTextStyles.labelBold,
                ),
                subtitle: Text(
                  '${p['phone'] ?? '—'}  ·  $childCount ${childCount == 1 ? 'child' : 'children'}',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: _StatusBadge(
                  label: p['is_active'] == true ? 'Active' : 'Inactive',
                  color: p['is_active'] == true ? AppColors.success : AppColors.danger,
                ),
                onTap: () => _showParentDetail(context, p),
              ),
            );
          },
        );
      },
    );
  }

  void _showParentDetail(BuildContext context, Map<String, dynamic> parent) {
    final childrenData = parent['children'] as List<dynamic>? ?? [];
    final childCount = childrenData.length;
    final name = parent['full_name'] as String? ?? 'Parent';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    bool isActive = parent['is_active'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgLight,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Avatar + Name ──────────────────────────────────────────
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: AppTextStyles.heading1.copyWith(color: AppColors.secondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(name, style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                _StatusBadge(
                  label: isActive ? 'Active' : 'Inactive',
                  color: isActive ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Info Card ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: parent['phone'] ?? '—',
                      ),
                      const Divider(height: AppSpacing.lg, color: AppColors.border),
                      // FIX: Show relationship_to_child from DB
                      if (parent['relationship_to_child'] != null) ...[
                        _DetailRow(
                          icon: Icons.family_restroom,
                          label: 'Relationship',
                          value: parent['relationship_to_child'] as String,
                        ),
                        const Divider(height: AppSpacing.lg, color: AppColors.border),
                      ],
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: 'Emergency Contact',
                        value: parent['emergency_contact_name'] ?? '—',
                      ),
                      const Divider(height: AppSpacing.lg, color: AppColors.border),
                      _DetailRow(
                        icon: Icons.contact_phone_outlined,
                        label: 'Emergency Phone',
                        value: parent['emergency_contact_phone'] ?? '—',
                      ),
                      const Divider(height: AppSpacing.lg, color: AppColors.border),
                      _DetailRow(
                        icon: Icons.child_care_rounded,
                        label: 'Children Enrolled',
                        value: '$childCount',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── FIX: Admin can toggle parent active status ─────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      isActive ? Icons.person_off_outlined : Icons.person_add_alt_1,
                      size: 18,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? AppColors.danger : AppColors.success,
                      side: BorderSide(
                          color: isActive ? AppColors.danger : AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonRadius),
                    ),
                    onPressed: () async {
                      try {
                        await _supabase
                            .from('parents')
                            .update({'is_active': !isActive})
                            .eq('id', parent['id']);
                        setDialogState(() => isActive = !isActive);
                        setState(() => _refresh());
                      } on PostgrestException catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.message}'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
                    label: Text(
                      isActive ? 'Deactivate Account' : 'Activate Account',
                      style: AppTextStyles.labelBold.copyWith(
                        color: isActive ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMedium,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.buttonRadius),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                child: Text('Close', style: AppTextStyles.labelBold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ──────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.labelBold),
            ],
          ),
        ),
      ],
    );
  }
}