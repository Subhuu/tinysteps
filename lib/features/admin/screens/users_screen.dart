import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

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
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('Users Management', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: context.textStyles.labelBold,
          unselectedLabelStyle: context.textStyles.labelMedium,
          indicatorColor: context.colors.primary,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.textMuted,
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
          return Center(child: CircularProgressIndicator(color: context.colors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: context.colors.danger, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Failed to load teachers', style: context.textStyles.bodyMuted),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    snapshot.error.toString(),
                    style: context.textStyles.caption.copyWith(color: context.colors.danger),
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
            child: Text('No teachers found', style: context.textStyles.bodyMuted),
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
              statusColor = context.colors.success;
            } else if (!isApproved) {
              statusLabel = 'Pending';
              statusColor = context.colors.warning;
            } else {
              statusLabel = 'Inactive';
              statusColor = context.colors.danger;
            }

            return Card(
              elevation: 0,
              color: context.colors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: context.colors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                leading: CircleAvatar(
                  backgroundColor: context.colors.primaryLight,
                  child: Text(
                    (t['full_name'] as String? ?? 'T')[0].toUpperCase(),
                    style: context.textStyles.labelBold.copyWith(color: context.colors.primary),
                  ),
                ),
                title: Text(t['full_name'] ?? 'Unknown', style: context.textStyles.labelBold),
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
                    style: context.textStyles.bodySmall,
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
          backgroundColor: context.colors.bgLight,
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
                  backgroundColor: context.colors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: context.textStyles.heading1.copyWith(color: context.colors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(name, style: context.textStyles.heading3),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    _StatusBadge(
                      label: isApproved ? 'Approved' : 'Pending',
                      color: isApproved ? context.colors.success : context.colors.warning,
                    ),
                    _StatusBadge(
                      label: isActive ? 'Active' : 'Inactive',
                      color: isActive ? context.colors.success : context.colors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Info card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    children: [
                      if (designation != null && designation.isNotEmpty) ...[
                        _DetailRow(
                          icon: Icons.badge_outlined,
                          label: 'Designation',
                          value: designation,
                        ),
                        Divider(height: AppSpacing.lg, color: context.colors.border),
                      ],
                      if (staffId != null && staffId.isNotEmpty) ...[
                        _DetailRow(
                          icon: Icons.numbers,
                          label: 'Staff ID',
                          value: staffId,
                        ),
                        Divider(height: AppSpacing.lg, color: context.colors.border),
                      ],
                      _DetailRow(
                        icon: Icons.meeting_room_outlined,
                        label: 'Classroom',
                        value: currentClassroomName,
                      ),
                      Divider(height: AppSpacing.lg, color: context.colors.border),
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
                        backgroundColor: context.colors.success,
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
                      label: Text('Approve', style: context.textStyles.buttonLabel),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.warning,
                        side: BorderSide(color: context.colors.warning),
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
                        style: context.textStyles.labelBold.copyWith(color: context.colors.warning),
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
                        foregroundColor: isActive ? context.colors.danger : context.colors.success,
                        side: BorderSide(color: isActive ? context.colors.danger : context.colors.success),
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
                        style: context.textStyles.labelBold.copyWith(
                          color: isActive ? context.colors.danger : context.colors.success,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // ── Assign Classroom ───────────────────────────────────
                Text('Assign Classroom', style: context.textStyles.labelBold),
                const SizedBox(height: AppSpacing.sm),
                if (classrooms.isEmpty)
                  Text('No classrooms available', style: context.textStyles.bodyMuted)
                else
                  DropdownButtonFormField<String>(
                    dropdownColor: context.colors.bgSurface,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.colors.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.inputRadius,
                        borderSide: BorderSide(color: context.colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.inputRadius,
                        borderSide: BorderSide(color: context.colors.border),
                      ),
                    ),
                    hint: Text('Select classroom', style: context.textStyles.bodyMuted),
                    initialValue: selectedClassroomId,
                    items: classrooms.map((c) {
                      // FIX: code is nullable — fallback to name only
                      final code = c['code'] as String?;
                      final label = code != null && code.isNotEmpty
                          ? '${c['name']} ($code)'
                          : '${c['name']}';
                      return DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(label, style: context.textStyles.bodyMedium),
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
                        backgroundColor: context.colors.secondary,
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
                                    SnackBar(
                                      content: Text('Classroom assigned successfully'),
                                      backgroundColor: context.colors.success,
                                    ),
                                  );
                                }
                                setState(() => _refresh());
                              } on PostgrestException catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.message}'),
                                      backgroundColor: context.colors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text('Confirm Assignment', style: context.textStyles.buttonLabel),
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
          return Center(child: CircularProgressIndicator(color: context.colors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: context.colors.danger, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Failed to load parents', style: context.textStyles.bodyMuted),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    snapshot.error.toString(),
                    style: context.textStyles.caption.copyWith(color: context.colors.danger),
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
            child: Text('No parents found', style: context.textStyles.bodyMuted),
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
              color: context.colors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: context.colors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                leading: CircleAvatar(
                  backgroundColor: context.colors.secondaryLight,
                  child: Text(
                    (p['full_name'] as String? ?? 'P')[0].toUpperCase(),
                    style: context.textStyles.labelBold
                        .copyWith(color: context.colors.secondary),
                  ),
                ),
                title: Text(
                  p['full_name'] ?? 'Unknown',
                  style: context.textStyles.labelBold,
                ),
                subtitle: Text(
                  '${p['phone'] ?? '—'}  ·  $childCount ${childCount == 1 ? 'child' : 'children'}',
                  style: context.textStyles.bodySmall,
                ),
                trailing: _StatusBadge(
                  label: p['is_active'] == true ? 'Active' : 'Inactive',
                  color: p['is_active'] == true ? context.colors.success : context.colors.danger,
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
          backgroundColor: context.colors.bgLight,
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
                  backgroundColor: context.colors.secondary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: context.textStyles.heading1.copyWith(color: context.colors.secondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(name, style: context.textStyles.heading3),
                const SizedBox(height: 4),
                _StatusBadge(
                  label: isActive ? 'Active' : 'Inactive',
                  color: isActive ? context.colors.success : context.colors.danger,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Info Card ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: parent['phone'] ?? '—',
                      ),
                      Divider(height: AppSpacing.lg, color: context.colors.border),
                      // FIX: Show relationship_to_child from DB
                      if (parent['relationship_to_child'] != null) ...[
                        _DetailRow(
                          icon: Icons.family_restroom,
                          label: 'Relationship',
                          value: parent['relationship_to_child'] as String,
                        ),
                        Divider(height: AppSpacing.lg, color: context.colors.border),
                      ],
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: 'Emergency Contact',
                        value: parent['emergency_contact_name'] ?? '—',
                      ),
                      Divider(height: AppSpacing.lg, color: context.colors.border),
                      _DetailRow(
                        icon: Icons.contact_phone_outlined,
                        label: 'Emergency Phone',
                        value: parent['emergency_contact_phone'] ?? '—',
                      ),
                      Divider(height: AppSpacing.lg, color: context.colors.border),
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
                      foregroundColor: isActive ? context.colors.danger : context.colors.success,
                      side: BorderSide(
                          color: isActive ? context.colors.danger : context.colors.success),
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
                              backgroundColor: context.colors.danger,
                            ),
                          );
                        }
                      }
                    },
                    label: Text(
                      isActive ? 'Deactivate Account' : 'Activate Account',
                      style: context.textStyles.labelBold.copyWith(
                        color: isActive ? context.colors.danger : context.colors.success,
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
                  foregroundColor: context.colors.textMedium,
                  side: BorderSide(color: context.colors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.buttonRadius),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                child: Text('Close', style: context.textStyles.labelBold),
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
        style: context.textStyles.bodySmall.copyWith(
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
        Icon(icon, size: 16, color: context.colors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textStyles.caption),
              Text(value, style: context.textStyles.labelBold),
            ],
          ),
        ),
      ],
    );
  }
}
