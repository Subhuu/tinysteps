import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

/// Admin Classroom Management — CRUD + detail + referral codes
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
    _classroomsFuture = _supabase
        .from('classrooms')
        .select(
          'id, name, code, age_group, max_capacity, teacher_id, '
          'teachers!classrooms_teacher_id_fkey(id, full_name), '
          'children(count)',
        )
        .order('name');
  }

  void _showReferralSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ReferralCodesSheet(),
    );
  }

  Future<void> _showUpsertDialog({Map<String, dynamic>? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _UpsertClassroomDialog(existing: existing),
    );
    if (result == true) {
      setState(() => _load());
    }
  }

  Future<void> _deleteClassroom(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Classroom?'),
        content: const Text('Children in this classroom will become unassigned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _supabase
          .from('children')
          .update({'classroom_id': null, 'teacher_id': null})
          .eq('classroom_id', id);

      await _supabase.from('classrooms').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Classroom deleted'), backgroundColor: AppColors.danger),
        );
      }
      setState(() => _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Classrooms', style: AppTextStyles.heading2),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined),
            tooltip: 'Referral Codes',
            onPressed: _showReferralSheet,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUpsertDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _load()),
        child: FutureBuilder<List<dynamic>>(
          future: _classroomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final classrooms = snapshot.data ?? [];
            if (classrooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.class_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md),
                    Text('No classrooms yet', style: AppTextStyles.heading3),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: classrooms.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final c = classrooms[index] as Map<String, dynamic>;
                return _ClassroomListItem(
                  classroom: c,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassroomDetailScreen(classroom: c),
                      ),
                    );
                    setState(() => _load());
                  },
                  onEdit: () => _showUpsertDialog(existing: c),
                  onDelete: () => _deleteClassroom(c['id'] as String),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ClassroomListItem extends StatelessWidget {
  final Map<String, dynamic> classroom;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassroomListItem({
    required this.classroom,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final teacherMap = classroom['teachers'] as Map<String, dynamic>?;
    final teacherName = teacherMap?['full_name'] as String? ?? 'Unassigned';
    final ageGroup = classroom['age_group'] as String? ?? '—';
    final countList = classroom['children'] as List<dynamic>?;
    final int childCount = (countList != null && countList.isNotEmpty)
        ? (countList[0]['count'] as int? ?? 0)
        : 0;
    final int maxCapacity = classroom['max_capacity'] as int? ?? 20;
    final double progress = maxCapacity > 0 ? childCount / maxCapacity : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.secondaryLight,
                child: Text(
                  (classroom['name'] as String? ?? 'C')[0].toUpperCase(),
                  style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classroom['name'] ?? '—', style: AppTextStyles.labelBold),
                    Text('Age: $ageGroup', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outlined, size: 14, color: teacherMap != null ? AppColors.success : AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(teacherName, style: AppTextStyles.caption),
                        const Spacer(),
                        Text('$childCount / $maxCapacity', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? AppColors.danger : AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpsertClassroomDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _UpsertClassroomDialog({this.existing});

  @override
  State<_UpsertClassroomDialog> createState() => _UpsertClassroomDialogState();
}

class _UpsertClassroomDialogState extends State<_UpsertClassroomDialog> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _capCtrl;
  String? _selectedTeacherId;
  List<dynamic> _teachers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?['name'] ?? '');
    _codeCtrl = TextEditingController(text: widget.existing?['code'] ?? '');
    _ageCtrl = TextEditingController(text: widget.existing?['age_group'] ?? '');
    _capCtrl = TextEditingController(text: (widget.existing?['max_capacity'] ?? 20).toString());
    _selectedTeacherId = widget.existing?['teacher_id'];
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      // Fetch approved/active teachers
      final data = await _supabase.from('teachers')
          .select('id, full_name')
          .eq('is_approved', true)
          .eq('is_active', true)
          .order('full_name');
      
      if (mounted) {
        setState(() {
          _teachers = data;
          // IMPORTANT: If current teacher is NOT in the active/approved list,
          // we MUST add them temporarily to avoid DropdownButton error
          if (_selectedTeacherId != null && !_teachers.any((t) => t['id'] == _selectedTeacherId)) {
            final existingTeacherName = widget.existing?['teachers']?['full_name'] ?? 'Current Teacher';
            _teachers.insert(0, {'id': _selectedTeacherId, 'full_name': '$existingTeacherName (Inactive)'});
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    final data = {
      'name': name,
      'code': _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim().toUpperCase(),
      'age_group': _ageCtrl.text.trim(),
      'max_capacity': int.tryParse(_capCtrl.text.trim()) ?? 20,
      'teacher_id': _selectedTeacherId,
    };

    try {
      if (widget.existing != null) {
        final classroomId = widget.existing!['id'];
        await _supabase.from('classrooms').update(data).eq('id', classroomId);
        
        // Sync children to the new teacher (even if null)
        await _supabase.from('children')
            .update({'teacher_id': _selectedTeacherId})
            .eq('classroom_id', classroomId);
            
      } else {
        await _supabase.from('classrooms').insert(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Create Classroom' : 'Edit Classroom'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
            const SizedBox(height: 8),
            TextField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Code (Optional)')),
            const SizedBox(height: 8),
            TextField(controller: _ageCtrl, decoration: const InputDecoration(labelText: 'Age Group')),
            const SizedBox(height: 8),
            TextField(controller: _capCtrl, decoration: const InputDecoration(labelText: 'Max Capacity'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedTeacherId,
              hint: const Text('Assign Teacher'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
                ..._teachers.map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['full_name'])))
              ],
              onChanged: (v) => setState(() => _selectedTeacherId = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _isLoading ? null : _save, child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save')),
      ],
    );
  }
}

// ==================== REFERRAL CODES SHEET ====================
class _ReferralCodesSheet extends StatefulWidget {
  const _ReferralCodesSheet();

  @override
  State<_ReferralCodesSheet> createState() => _ReferralCodesSheetState();
}

class _ReferralCodesSheetState extends State<_ReferralCodesSheet> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _codes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCodes();
  }

  Future<void> _fetchCodes() async {
    try {
      final data = await _supabase.from('referral_codes').select().order('created_at', ascending: false);
      if (mounted) setState(() { _codes = data; _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _generateCode() async {
    String selectedRole = 'parent';
    DateTime expiry = DateTime.now().add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Generate Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                items: ['parent', 'teacher', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setS(() => selectedRole = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: Text(expiry.toLocal().toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final p = await showDatePicker(context: context, initialDate: expiry, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (p != null) setS(() => expiry = p);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final code = 'TINY-${Random().nextInt(9000) + 1000}';
                await _supabase.from('referral_codes').insert({
                  'code': code, 'role': selectedRole, 'expires_at': expiry.toIso8601String(), 'created_by': _supabase.auth.currentUser?.id,
                });
                if (ctx.mounted) { Navigator.pop(ctx); _fetchCodes(); }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: AppRadius.sheetRadius),
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, MediaQuery.of(context).viewInsets.bottom + AppSpacing.md),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Referral Codes', style: AppTextStyles.heading2),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(onPressed: _generateCode, icon: const Icon(Icons.add), label: const Text('New Code'), style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50))),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
              itemCount: _codes.length,
              itemBuilder: (context, i) {
                final item = _codes[i];
                final bool isUsed = item['is_used'] ?? false;
                final bool isExpired = DateTime.parse(item['expires_at']).isBefore(DateTime.now());
                final status = isUsed ? 'Used' : (isExpired ? 'Expired' : 'Active');
                final color = isUsed ? AppColors.info : (isExpired ? AppColors.danger : AppColors.success);

                return ListTile(
                  title: Text(item['code'], style: AppTextStyles.labelBold),
                  subtitle: Text('Role: ${item['role']} • Exp: ${item['expires_at'].split('T')[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(status, style: TextStyle(color: color, fontSize: 12))),
                      IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () { Clipboard.setData(ClipboardData(text: item['code'])); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'))); }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CLASSROOM DETAIL SCREEN ====================
class ClassroomDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classroom;
  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  final _supabase = Supabase.instance.client;
  late Map<String, dynamic> _currentClassroom;
  List<dynamic> _children = [];
  List<dynamic> _unassigned = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentClassroom = Map.from(widget.classroom);
    _refresh(silent: false);
  }

  Future<void> _refresh({bool silent = true}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final updated = await _supabase.from('classrooms')
          .select('*, teachers!classrooms_teacher_id_fkey(id, full_name)')
          .eq('id', _currentClassroom['id'])
          .single();
          
      final children = await _supabase.from('children')
          .select('*')
          .eq('classroom_id', _currentClassroom['id']);
          
      final unassigned = await _supabase.from('children')
          .select('*')
          .isFilter('classroom_id', null);
          
      if (mounted) {
        setState(() {
          _currentClassroom = updated;
          _children = children;
          _unassigned = unassigned;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteClassroom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Classroom?'),
        content: const Text('Children in this classroom will become unassigned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final id = _currentClassroom['id'];
      await _supabase.from('children').update({
        'classroom_id': null,
        'teacher_id': null,
      }).eq('classroom_id', id);

      await _supabase.from('classrooms').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Classroom deleted'), backgroundColor: AppColors.danger),
        );
        Navigator.pop(context); // Go back to the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = _currentClassroom['teachers']?['full_name'] ?? 'Unassigned';
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentClassroom['name'] ?? 'Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () async {
            final res = await showDialog<bool>(context: context, builder: (_) => _UpsertClassroomDialog(existing: _currentClassroom));
            if (res == true) _refresh(silent: true);
          }),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.danger),
            onPressed: _deleteClassroom,
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _info('Age Group', _currentClassroom['age_group'] ?? 'N/A'),
                    const Divider(),
                    _info('Capacity', '${_children.length} / ${_currentClassroom['max_capacity'] ?? 20}'),
                    const Divider(),
                    _info('Teacher', teacherName),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Children (${_children.length})', style: AppTextStyles.heading3),
            ..._children.map((c) => _childRow(c, isAssigned: true)),
            if (_unassigned.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Unassigned (${_unassigned.length})', style: AppTextStyles.heading3),
              ..._unassigned.map((c) => _childRow(c, isAssigned: false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: AppTextStyles.bodyMuted), Text(v, style: AppTextStyles.labelBold)]));

  Widget _childRow(dynamic c, {required bool isAssigned}) => ListTile(
    title: Text(c['full_name'] ?? 'Unknown'),
    leading: const CircleAvatar(child: Icon(Icons.child_care, size: 18)),
    trailing: isAssigned
      ? IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger), onPressed: () async {
          await _supabase.from('children').update({'classroom_id': null, 'teacher_id': null}).eq('id', c['id']);
          _refresh(silent: true);
        })
      : FilledButton(onPressed: () async {
          await _supabase.from('children').update({'classroom_id': _currentClassroom['id'], 'teacher_id': _currentClassroom['teacher_id']}).eq('id', c['id']);
          _refresh(silent: true);
        }, child: const Text('Assign')),
  );
}
