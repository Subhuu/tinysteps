import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Admin Classroom Management — CRUD + assign teacher
class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({super.key});

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<dynamic>> _classroomsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // Fetch classrooms — use !left join hint for nullable teacher_id
    _classroomsFuture = _supabase
        .from('classrooms')
        .select('id, name, code, age_group, max_capacity, teacher_id, teachers!classrooms_teacher_id_fkey(full_name)')
        .order('name');
  }

  // ── Create/Edit dialog ──────────────────────────────────────────────────────
  Future<void> _showUpsertDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final codeCtrl = TextEditingController(text: existing?['code'] ?? '');
    final ageCtrl = TextEditingController(text: existing?['age_group'] ?? '');
    final capCtrl = TextEditingController(
      text: (existing?['max_capacity'] ?? 20).toString(),
    );
    final isEdit = existing != null;

    // Fetch approved active teachers for picker
    final teachers = await _supabase
        .from('teachers')
        .select('id, full_name')
        .eq('is_approved', true)
        .eq('is_active', true)
        .order('full_name');

    if (!mounted) return;

    String? selectedTeacherId = existing?['teacher_id'] as String?;

    await showDialog(
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
                // ── Header icon + title ────────────────────────────────
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  child: Icon(
                    isEdit ? Icons.edit_outlined : Icons.add_home_work_outlined,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isEdit ? 'Edit Classroom' : 'Create Classroom',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Fields ─────────────────────────────────────────────
                _field(nameCtrl, 'Classroom Name', Icons.class_),
                const SizedBox(height: AppSpacing.sm),
                _field(codeCtrl, 'Unique Code (e.g. SUN-101)', Icons.qr_code),
                const SizedBox(height: AppSpacing.sm),
                _field(ageCtrl, 'Age Group (e.g. 2-3 yrs)', Icons.cake_outlined),
                const SizedBox(height: AppSpacing.sm),
                _field(capCtrl, 'Max Capacity', Icons.groups,
                    keyboardType: TextInputType.number),
                const SizedBox(height: AppSpacing.md),

                // ── Teacher picker ─────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: selectedTeacherId,
                  hint: Text('Assign Teacher', style: AppTextStyles.bodyMuted),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...teachers.map((row) {
                      return DropdownMenuItem<String>(
                        value: row['id'] as String,
                        child: Text(
                          row['full_name'] as String? ?? '—',
                          style: AppTextStyles.bodyMedium,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedTeacherId = val),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Action buttons ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                        ),
                        child: Text('Cancel', style: AppTextStyles.labelBold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                        ),
                        onPressed: () async {
                          final data = {
                            'name': nameCtrl.text.trim(),
                            'code': codeCtrl.text.trim().toUpperCase(),
                            'age_group': ageCtrl.text.trim().isEmpty
                                ? null
                                : ageCtrl.text.trim(),
                            'max_capacity':
                                int.tryParse(capCtrl.text.trim()) ?? 20,
                            'teacher_id': selectedTeacherId,
                          };

                          try {
                            if (isEdit) {
                              await _supabase
                                  .from('classrooms')
                                  .update(data)
                                  .eq('id', existing['id']);
                              if (selectedTeacherId != null) {
                                await _supabase
                                    .from('children')
                                    .update({'teacher_id': selectedTeacherId})
                                    .eq('classroom_id', existing['id']);
                              }
                            } else {
                              await _supabase.from('classrooms').insert(data);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            setState(() => _load());
                          } on PostgrestException catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text('Error: ${e.message}'),
                                backgroundColor: AppColors.danger,
                              ));
                            }
                          }
                        },
                        child: Text(isEdit ? 'Save' : 'Create',
                            style: AppTextStyles.buttonLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  Future<void> _deleteClassroom(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        title: Text('Delete Classroom?', style: AppTextStyles.heading3),
        content: Text(
            'Children in this classroom will become unassigned.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppTextStyles.labelBold.copyWith(color: AppColors.textMuted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Unassign children first
    await _supabase
        .from('children')
        .update({'classroom_id': null, 'teacher_id': null})
        .eq('classroom_id', id);
    await _supabase.from('classrooms').delete().eq('id', id);
    setState(() => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Classrooms', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showUpsertDialog(),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => setState(() => _load()),
        child: FutureBuilder<List<dynamic>>(
          future: _classroomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load classrooms',
                    style: AppTextStyles.bodyMuted),
              );
            }
            final classrooms = snapshot.data ?? [];
            if (classrooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.class_outlined,
                        size: 64,
                        color: AppColors.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('No classrooms yet', style: AppTextStyles.heading3),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Tap + to create your first classroom',
                        style: AppTextStyles.bodyMuted),
                  ],
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: classrooms.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final c = classrooms[index] as Map<String, dynamic>;
                final teacherMap = c['teachers'] as Map<String, dynamic>?;
                final teacherName =
                    teacherMap?['full_name'] as String? ?? 'Unassigned';

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
                        radius: 24,
                        backgroundColor: AppColors.secondaryLight,
                        child: Text(
                          (c['name'] as String? ?? 'C')[0].toUpperCase(),
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] ?? '—',
                                style: AppTextStyles.labelBold),
                            Text(
                              'Code: ${c['code'] ?? '—'}  ·  ${c['age_group'] ?? '—'}',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              'Teacher: $teacherName  ·  Max: ${c['max_capacity'] ?? 20}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showUpsertDialog(existing: c);
                          } else if (val == 'delete') {
                            _deleteClassroom(c['id'] as String);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                        ],
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
}
