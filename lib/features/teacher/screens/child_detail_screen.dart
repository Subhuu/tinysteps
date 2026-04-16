import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tinysteps/core/constants/app_theme.dart';

class ChildDetailScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildDetailScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  final _supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _loadChildDetails();
  }

  Future<Map<String, dynamic>> _loadChildDetails() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Fetch child info
    final childRow = await _supabase
        .from('children')
        .select('*')
        .eq('id', widget.childId)
        .maybeSingle();

    // Fetch today's attendance for this child
    final attendanceRow = await _supabase
        .from('attendance')
        .select('checked_in_at, checked_out_at')
        .eq('child_id', widget.childId)
        .eq('date', today)
        .maybeSingle();

    return {'child': childRow ?? {}, 'attendance': attendanceRow};
  }

  String _calcAge(String dob) {
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      int years = now.year - birth.year;
      int months = now.month - birth.month;
      if (now.day < birth.day) months--;
      if (months < 0) {
        years--;
        months += 12;
      }
      if (years > 0) return '$years yr${years > 1 ? 's' : ''}';
      return '$months month${months != 1 ? 's' : ''}';
    } catch (_) {
      return 'Unknown age';
    }
  }

  String _formatTime(String? raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '—';
    }
  }

  Widget _buildField(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isAlert ? AppColors.danger : AppColors.textDark,
              fontWeight: isAlert ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 👇 Emergency contact UI only
  Widget _buildParentCallCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Parent avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondaryLight,
            child: Text(
              'P',
              style: AppTextStyles.labelBold.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name and number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mother: Priya Sharma', style: AppTextStyles.labelBold),
                const SizedBox(height: 2),
                Text(
                  '+91 98765 43210',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Call button
          ElevatedButton.icon(
            onPressed: () async {
              final Uri url = Uri(scheme: 'tel', path: '+919876543210');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            icon: const Icon(Icons.phone_rounded, size: 16),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(widget.childName, style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/teacher');
            }
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading details\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
            );
          }

          final data = snapshot.data;
          final child = data?['child'] as Map<String, dynamic>? ?? {};
          final attendance = data?['attendance'] as Map<String, dynamic>?;

          final name = child['full_name'] as String? ?? widget.childName;
          final dob = child['date_of_birth'] as String?;
          final ageStr = dob != null ? _calcAge(dob) : 'Unknown age';
          final gender = child['gender'] as String? ?? 'N/A';
          final allergies = child['allergies'] as String?;
          final status = child['status'] as String? ?? 'active';

          final checkInStr = attendance != null
              ? _formatTime(attendance['checked_in_at'])
              : 'Not here';
          final checkOutStr = attendance != null
              ? _formatTime(attendance['checked_out_at'])
              : '—';

          final isCheckedIn =
              (attendance != null &&
              attendance['checked_in_at'] != null &&
              attendance['checked_out_at'] == null);
          final hasAllergies =
              allergies != null &&
              allergies.trim().isNotEmpty &&
              allergies.toLowerCase() != 'none';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.primary,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(name, style: AppTextStyles.heading1),
                      const SizedBox(height: 4),
                      Text(ageStr, style: AppTextStyles.bodyMuted),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCheckedIn
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          isCheckedIn
                              ? 'Currently In Class'
                              : (status == 'checked_out'
                                    ? 'Picked Up'
                                    : 'Enrolled'),
                          style: AppTextStyles.labelBold.copyWith(
                            color: isCheckedIn
                                ? AppColors.success
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // 👇 Emergency Contact Section
                Text('Emergency Contact', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.md),
                _buildParentCallCard(),
                const SizedBox(height: AppSpacing.xxl),

                // Attendance Section
                Text('Today\'s Attendance', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Check In', style: AppTextStyles.bodyMuted),
                          const SizedBox(height: 4),
                          Text(
                            checkInStr,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Column(
                        children: [
                          Text('Check Out', style: AppTextStyles.bodyMuted),
                          const SizedBox(height: 4),
                          Text(
                            checkOutStr,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Details Section
                Text('Child Information', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField('Full Name', name),
                      _buildField('Date of Birth', dob ?? 'N/A'),
                      _buildField('Gender', gender),
                      if (hasAllergies)
                        _buildField(
                          'Allergies & Medical Notes',
                          allergies,
                          isAlert: true,
                        ),
                      if (!hasAllergies)
                        _buildField('Allergies', 'None reported'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
