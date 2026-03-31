import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tinysteps/core/constants/app_theme.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<dynamic>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      _recordsFuture = Future.value([]);
      return;
    }

    // Single query: join through children → only this parent's records
    // Uses !inner to filter by parent_id at the DB level (not client-side)
    _recordsFuture = _supabase
        .from('attendance')
        .select('date, checked_in_at, checked_out_at, method, children!inner(full_name, parent_id)')
        .eq('children.parent_id', uid)
        .order('date', ascending: false)
        .limit(50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Attendance', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => setState(() => _load()),
        child: FutureBuilder<List<dynamic>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load attendance.\nPull down to retry.',
                  style: AppTextStyles.bodyMuted,
                  textAlign: TextAlign.center,
                ),
              );
            }

            final records = snapshot.data ?? [];

            if (records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('No attendance records yet.', style: AppTextStyles.heading3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Records will appear here once a teacher\nscans your child\'s QR code.',
                      style: AppTextStyles.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final r = records[index] as Map<String, dynamic>;
                final childData = r['children'] as Map<String, dynamic>? ?? {};
                final childName = childData['full_name'] as String? ?? 'Child';

                final date = _parseDate(r['date'] as String?);
                final checkIn = _parseTime(r['checked_in_at'] as String?);
                final checkOut = _parseTime(r['checked_out_at'] as String?);
                final method = r['method'] as String? ?? 'qr';

                return _AttendanceCard(
                  childName: childName,
                  date: date,
                  checkIn: checkIn,
                  checkOut: checkOut,
                  method: method,
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _parseDate(String? raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _parseTime(String? raw) {
    if (raw == null) return '—';
    try {
      final utc = DateTime.parse(raw);
      final local = utc.toLocal();
      return DateFormat('hh:mm a').format(local);
    } catch (_) {
      return '—';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance record card
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  final String childName;
  final String date;
  final String checkIn;
  final String checkOut;
  final String method;

  const _AttendanceCard({
    required this.childName,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = checkOut != '—';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: child name + status badge
          Row(
            children: [
              Expanded(
                child: Text(childName, style: AppTextStyles.labelBold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isComplete ? 'Completed' : 'In Progress',
                  style: AppTextStyles.caption.copyWith(
                    color: isComplete ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(date, style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.md),

          // Check-in / check-out times
          Row(
            children: [
              Expanded(
                child: _TimeBlock(
                  label: 'Check-In',
                  time: checkIn,
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TimeBlock(
                  label: 'Check-Out',
                  time: checkOut,
                  icon: Icons.logout_rounded,
                  color: checkOut == '—' ? AppColors.textMuted : AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Method badge
              Column(
                children: [
                  Icon(
                    method == 'qr' ? Icons.qr_code : Icons.touch_app,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  Text(method.toUpperCase(), style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _TimeBlock({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: AppTextStyles.labelBold.copyWith(
            color: time == '—' ? AppColors.textMuted : color,
          ),
        ),
      ],
    );
  }
}
