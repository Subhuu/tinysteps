import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class MyClassroomScreen extends StatefulWidget {
  const MyClassroomScreen({super.key});

  @override
  State<MyClassroomScreen> createState() => _MyClassroomScreenState();
}

class _MyClassroomScreenState extends State<MyClassroomScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchClassrooms();
  }

  Future<List<Map<String, dynamic>>> _fetchClassrooms() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return [];

    final classrooms = await _supabase
        .from('classrooms')
        .select('*')
        .eq('teacher_id', uid)
        .order('name');

    return List<Map<String, dynamic>>.from(classrooms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Classroom Settings',
          style: AppTextStyles.labelBold.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {

          /// LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          ///  ERROR
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Something went wrong.\nPlease try again.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            );
          }

          final classrooms = snapshot.data ?? [];

          /// EMPTY STATE
          if (classrooms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 72,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No Classrooms Yet',
                      style: AppTextStyles.labelBold.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You will see your classrooms here\nonce assigned by admin.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            );
          }

          // MAIN UI
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Section Title
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Your Classrooms',
                  style: AppTextStyles.labelBold.copyWith(fontSize: 18),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: classrooms.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final c = classrooms[index];
                    return _buildClassroomCard(c);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ///  CARD UI
  Widget _buildClassroomCard(Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'Unnamed Classroom';
    final ageRange = data['age_range'] as String? ?? 'N/A';
    final capacity = data['capacity']?.toString() ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded,
                    color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.labelBold,
                  ),
                ),
              ],
            ),
          ),

          /// Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                    Icons.escalator_warning_rounded, 'Age Range', ageRange),
                const SizedBox(height: AppSpacing.md),
                _buildInfoRow(
                    Icons.groups_rounded, 'Capacity Limit', capacity),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(),
                ),

                /// Button
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Roster report coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Report'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Text('$label:', style: AppTextStyles.bodyMuted),
        const SizedBox(width: AppSpacing.sm),
        Text(value, style: AppTextStyles.labelBold),
      ],
    );
  }
}