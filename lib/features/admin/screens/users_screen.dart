import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users Management"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Teachers"),
            Tab(text: "Parents"),
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

  // ---------------- TEACHERS TAB ----------------
  Widget _buildTeachersTab() {
    return FutureBuilder<List<dynamic>>(
      future: supabase.from('teachers').select(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final teachers = snapshot.data!;

        if (teachers.isEmpty) {
          return const Center(child: Text("No teachers found"));
        }

        return ListView.builder(
          itemCount: teachers.length,
          itemBuilder: (context, index) {
            final teacher = teachers[index] as Map<String, dynamic>;
            final status = teacher['is_approved'] == true
                ? "Active"
                : teacher['is_active'] == false
                ? "Inactive"
                : "Pending";

            final badgeColor = status == "Active"
                ? AppColors.primary
                : status == "Inactive"
                ? AppColors.warning
                : AppColors.secondary;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(teacher['name'] ?? 'Unknown'),
                subtitle: Text("Staff ID: ${teacher['staff_id'] ?? ''}"),
                trailing: Chip(
                  label: Text(status, style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: badgeColor,
                ),
                onTap: () => _showTeacherDetail(context, teacher),
              ),
            );
          },
        );
      },
    );
  }

  void _showTeacherDetail(BuildContext context, Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Teacher: ${teacher['name'] ?? ''}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed: () async {
                  await supabase.from('teachers').update({'is_approved': true}).eq('id', teacher['id']);
                  Navigator.pop(context);
                  if (mounted) setState(() {});
                },
                child: const Text("Approve"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed: () async {
                  await supabase.from('teachers').update({'is_active': false}).eq('id', teacher['id']);
                  Navigator.pop(context);
                  if (mounted) setState(() {});
                },
                child: const Text("Reject"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed: () async {
                  await supabase.from('classrooms').update({'teacher_id': teacher['id']}).eq('id', 1);
                  await supabase.from('children').update({'teacher_id': teacher['id']}).eq('classroom_id', 1);
                  Navigator.pop(context);
                  if (mounted) setState(() {});
                },
                child: const Text("Assign Classroom"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- PARENTS TAB ----------------
  Widget _buildParentsTab() {
    return FutureBuilder<List<dynamic>>(
      future: supabase.from('parents').select(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final parents = snapshot.data!;

        if (parents.isEmpty) {
          return const Center(child: Text("No parents found"));
        }

        return ListView.builder(
          itemCount: parents.length,
          itemBuilder: (context, index) {
            final parent = parents[index] as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.primaryLight,
              child: ListTile(
                title: Text(
                  parent['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary,),
                ),
                subtitle: Text("Phone: ${parent['phone'] ?? ''} | Children: ${parent['children_count'] ?? 0}",
                  style: const TextStyle(color: AppColors.secondary),
                ),
                trailing: Chip(
                  label: const Text("Parent", style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AppColors.warning,
                ),
                onTap: () => _showParentDetail(context, parent),
              ),
            );
          },
        );
      },
    );
  }

  void _showParentDetail(BuildContext context, Map<String, dynamic> parent) {
    showDialog(context: context, builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Parent: ${parent['name'] ?? ''}",
            style: const TextStyle(color: AppColors.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Emergency Contact: ${parent['emergency_contact'] ?? ''}",
                style: const TextStyle(color: AppColors.warning),
              ),
              const SizedBox(height: 10),
              Text("Linked Children: ${parent['children_list'] ?? ''}",
                style: const TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
        );
      },
    );
  }
}