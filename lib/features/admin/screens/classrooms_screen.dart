import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({super.key});

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _classrooms = [];

  @override
  void initState() {
    super.initState();
    _fetchClassrooms();
  }

  Future<void> _fetchClassrooms() async {
    try {
      final data = await _supabase
          .from('classrooms')
          .select('*, teachers(full_name), children(count)');
      setState(() {
        _classrooms = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching classrooms: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Classrooms', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classrooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchClassrooms,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _classrooms.length,
                    itemBuilder: (context, index) {
                      final classroom = _classrooms[index];
                      return _ClassroomCard(
                        classroom: classroom,
                        onTap: () => _showClassroomDetail(classroom),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassroomDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text('No classrooms found', style: AppTextStyles.heading3),
          Text('Add your first classroom to get started.',
              style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }

  void _showClassroomDetail(dynamic classroom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassroomDetailScreen(
          classroom: classroom,
          onUpdate: _fetchClassrooms,
        ),
      ),
    );
  }

  void _showAddClassroomDialog() {
    // TODO: Implement add classroom dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Classroom feature coming soon!')),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final dynamic classroom;
  final VoidCallback onTap;

  const _ClassroomCard({required this.classroom, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final int childCount = (classroom['children'] as List).isNotEmpty 
        ? classroom['children'][0]['count'] 
        : 0;
    final int capacity = classroom['capacity'] ?? 0;
    final double progress = capacity > 0 ? childCount / capacity : 0;
    final String teacherName = classroom['teachers']?['full_name'] ?? 'Unassigned';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(classroom['name'] ?? 'Unnamed Class',
                            style: AppTextStyles.heading3),
                        Text('Age: ${classroom['age_group'] ?? "N/A"}',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '$childCount / $capacity',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Teacher: $teacherName', style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppColors.danger : AppColors.primary,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassroomDetailScreen extends StatefulWidget {
  final dynamic classroom;
  final VoidCallback onUpdate;

  const ClassroomDetailScreen(
      {super.key, required this.classroom, required this.onUpdate});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _children = [];
  List<dynamic> _unassignedChildren = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final classroomId = widget.classroom['id'];
      
      // Fetch children in this classroom
      final childrenData = await _supabase
          .from('children')
          .select('*')
          .eq('classroom_id', classroomId);

      // Fetch unassigned children
      final unassignedData = await _supabase
          .from('children')
          .select('*')
          .isFilter('classroom_id', null);

      setState(() {
        _children = childrenData;
        _unassignedChildren = unassignedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignChild(dynamic child) async {
    try {
      await _supabase.from('children').update({
        'classroom_id': widget.classroom['id'],
        'teacher_id': widget.classroom['teacher_id'],
      }).eq('id', child['id']);
      
      _fetchData();
      widget.onUpdate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning child: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(widget.classroom['name'] ?? 'Detail',
            style: AppTextStyles.heading3),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Children in Class (${_children.length})',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: AppSpacing.sm),
                  _buildChildrenList(),
                  const SizedBox(height: AppSpacing.lg),
                  if (_unassignedChildren.isNotEmpty) ...[
                    Text('Assign Children', style: AppTextStyles.heading3),
                    const SizedBox(height: AppSpacing.sm),
                    _buildUnassignedList(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _InfoRow(label: 'Age Group', value: widget.classroom['age_group'] ?? 'N/A'),
            const Divider(),
            _InfoRow(label: 'Capacity', value: '${widget.classroom['capacity']} children'),
            const Divider(),
            _InfoRow(label: 'Teacher', value: widget.classroom['teachers']?['full_name'] ?? 'Unassigned'),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList() {
    if (_children.isEmpty) {
      return const Text('No children assigned to this classroom.');
    }
    return Column(
      children: _children.map((child) => ListTile(
        title: Text(child['full_name'] ?? 'Unknown Child'),
        leading: const CircleAvatar(child: Icon(Icons.child_care)),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      )).toList(),
    );
  }

  Widget _buildUnassignedList() {
    return Column(
      children: _unassignedChildren.map((child) => ListTile(
        title: Text(child['full_name'] ?? 'Unknown Child'),
        trailing: ElevatedButton(
          onPressed: () => _assignChild(child),
          child: const Text('Assign'),
        ),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      )).toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMuted),
          Text(value, style: AppTextStyles.labelBold),
        ],
      ),
    );
  }
}
