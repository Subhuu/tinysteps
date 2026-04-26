import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/features/parent/widgets/attendance_card.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

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
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('Attendance', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async => setState(() => _load()),
        child: FutureBuilder<List<dynamic>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: context.colors.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load attendance.\nPull down to retry.',
                  style: context.textStyles.bodyMuted,
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
                      color: context.colors.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('No attendance records yet.', style: context.textStyles.heading3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Records will appear here once a teacher\nscans your child\'s QR code.',
                      style: context.textStyles.bodyMuted,
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

                return AttendanceCard(
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

