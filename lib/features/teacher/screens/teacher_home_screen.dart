import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/widgets/bottom_nav_bar.dart';
import 'package:tinysteps/core/widgets/logout_dialog.dart';
import 'package:tinysteps/features/teacher/screens/teacher_settings_screen.dart';
import 'package:tinysteps/core/widgets/app_calendar.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

/// Teacher Home Shell — wraps all teacher tab screens with shared BottomNavBar.
/// Includes an approval gate: unapproved teachers see a pending screen.
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  final _supabase = Supabase.instance.client;

  // null = still loading, true = approved & active, false = blocked
  bool? _isApproved;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _TeacherDashboardTab(),
      const _TeacherAttendanceTab(),
      const _TeacherChildrenTab(),
      const TeacherSettingsScreen(),
    ];
    _checkApproval();
  }

  Future<void> _checkApproval() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await _supabase
          .from('teachers')
          .select('is_approved, is_active')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _isApproved =
            row != null &&
            row['is_approved'] == true &&
            row['is_active'] == true;
      });
    } catch (_) {
      if (mounted) setState(() => _isApproved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Still loading
    if (_isApproved == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      );
    }

    // Not approved — show gate
    if (_isApproved == false) {
      return _PendingApprovalScreen(
        onRefresh: () async {
          setState(() => _isApproved = null);
          await _checkApproval();
        },
        onSignOut: () => _supabase.auth.signOut(),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavBarItem(icon: Icons.home_rounded, label: 'Home'),
            BottomNavBarItem(
              icon: Icons.assignment_rounded,
              label: 'Attendance',
            ),
            BottomNavBarItem(icon: Icons.face_rounded, label: 'Children'),
            BottomNavBarItem(icon: Icons.settings_rounded, label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending approval gate
// ─────────────────────────────────────────────────────────────────────────────
class _PendingApprovalScreen extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onSignOut;

  const _PendingApprovalScreen({
    required this.onRefresh,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('TinySteps', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: onSignOut,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: context.colors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 72,
                  color: context.colors.warning,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Pending Approval', style: context.textStyles.heading1),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your account is waiting for admin approval.\n'
                'You\'ll be able to access the dashboard\nonce an admin approves your account.',
                style: context.textStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    side: BorderSide(color: context.colors.primary),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard tab
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherDashboardTab extends StatelessWidget {
  const _TeacherDashboardTab();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Teacher';

    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('TinySteps', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirmed = await showLogoutDialog(context);
              if (confirmed) {
                await Supabase.instance.client.auth.signOut();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good day, $name', style: context.textStyles.heading1),
            Text('Ready to take attendance?', style: context.textStyles.bodyMuted),
            const SizedBox(height: AppSpacing.xl),

            // Scan QR — primary CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/teacher/attendance'),
                icon: Icon(Icons.qr_code_scanner, color: context.colors.white),
                label: Text('Scan QR Code', style: context.textStyles.buttonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),


            ),

            const SizedBox(height: AppSpacing.lg),
            Text('Calendar', style: context.textStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            const AppCalendar(),

            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today\'s Attendance', style: context.textStyles.heading2),
                Text(
                  DateFormat('dd MMM').format(DateTime.now()),
                  style: context.textStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _TodayAttendanceSummary(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's attendance summary — real data from DB
// ─────────────────────────────────────────────────────────────────────────────
class _TodayAttendanceSummary extends StatefulWidget {
  @override
  State<_TodayAttendanceSummary> createState() =>
      _TodayAttendanceSummaryState();
}

class _TodayAttendanceSummaryState extends State<_TodayAttendanceSummary> {
  final _supabase = Supabase.instance.client;
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final uid = _supabase.auth.currentUser?.id;

    // Fetch today's attendance for children assigned to this teacher
    _future = _supabase
        .from('attendance')
        .select('child_id, checked_in_at, checked_out_at, children!inner(full_name, teacher_id)')
        .eq('date', today)
        .eq('children.teacher_id', uid ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(color: context.colors.primary),
            ),
          );
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.colors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: context.colors.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('No scans yet today', style: context.textStyles.bodyMuted),
                Text(
                  'Tap "Scan QR Code" above to mark attendance',
                  style: context.textStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return Column(
          children: records.map((r) {
            final row = r as Map<String, dynamic>;
            final child = row['children'] as Map<String, dynamic>? ?? {};
            final name = child['full_name'] as String? ?? 'Child';
            final checkIn = _formatTime(row['checked_in_at'] as String?);
            final checkOut = row['checked_out_at'] != null
                ? _formatTime(row['checked_out_at'] as String?)
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  final id = row['child_id']?.toString() ?? '';
                  if (id.isNotEmpty) {
                    context.push('/teacher/child/$id?name=${Uri.encodeComponent(name)}');
                  }
                },
                child: _AttendanceTile(
                  name: name,
                  checkIn: checkIn,
                  checkOut: checkOut,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatTime(String? raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '—';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance tab — opens the QR scanner directly
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherAttendanceTab extends StatelessWidget {
  const _TeacherAttendanceTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('Attendance', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: context.colors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Scan to Mark Attendance', style: context.textStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ask the parent to open their child\'s QR code '
              'in the TinySteps parent app, then scan it here.',
              style: context.textStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/teacher/attendance'),
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text('Open Scanner', style: context.textStyles.buttonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Children tab — lists children assigned to this teacher
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherChildrenTab extends StatefulWidget {
  const _TeacherChildrenTab();

  @override
  State<_TeacherChildrenTab> createState() => _TeacherChildrenTabState();
}

class _TeacherChildrenTabState extends State<_TeacherChildrenTab> {
  final _supabase = Supabase.instance.client;
  late Future<List<dynamic>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = _supabase.auth.currentUser?.id;
    _childrenFuture = _supabase
        .from('children')
        .select('id, full_name, date_of_birth, gender, allergies, status')
        .eq('teacher_id', uid ?? '')
        .order('full_name');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('My Children', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Classroom Settings',
            onPressed: () => context.push('/teacher/classroom'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async => setState(() => _load()),
        child: FutureBuilder<List<dynamic>>(
          future: _childrenFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: context.colors.primary),
              );
            }
            final children = snapshot.data ?? [];
            if (children.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.face_outlined,
                        size: 64,
                        color: context.colors.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No children assigned yet',
                        style: context.textStyles.heading3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Admin will assign children to you\nonce they are enrolled.',
                        style: context.textStyles.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final c = children[index] as Map<String, dynamic>;
                final status = c['status'] as String? ?? 'active';
                final dob = c['date_of_birth'] as String?;
                final age = dob != null ? _calcAge(dob) : null;
                final nameStr = c['full_name'] as String? ?? 'Child';
                return GestureDetector(
                  onTap: () {
                    final id = c['id']?.toString() ?? '';
                    if (id.isNotEmpty) {
                      context.push('/teacher/child/$id?name=${Uri.encodeComponent(nameStr)}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: context.colors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: context.colors.primaryLight,
                          child: Text(
                            nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'C',
                            style: context.textStyles.heading3.copyWith(color: context.colors.primary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nameStr, style: context.textStyles.labelBold),
                              if (age != null)
                                Text(age, style: context.textStyles.bodySmall),
                              if (c['allergies'] != null &&
                                  (c['allergies'] as String).isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber,
                                        size: 12, color: context.colors.warning),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        c['allergies'] as String,
                                        style: context.textStyles.caption.copyWith(
                                          color: context.colors.warning,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        _statusBadge(status),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
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
      return '';
    }
  }

  Widget _statusBadge(String status) {
    final color = switch (status) {
      'checked_in' => context.colors.success,
      'checked_out' => context.colors.textMuted,
      _ => context.colors.secondary,
    };
    final label = switch (status) {
      'checked_in' => 'In Class',
      'checked_out' => 'Picked Up',
      _ => 'Enrolled',
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: context.textStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance tile used in the dashboard summary
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceTile extends StatelessWidget {
  final String name;
  final String checkIn;
  final String? checkOut;

  const _AttendanceTile({
    required this.name,
    required this.checkIn,
    this.checkOut,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = checkOut != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.colors.primaryLight,
            child: Text(
              name[0].toUpperCase(),
              style: context.textStyles.labelBold.copyWith(color: context.colors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.textStyles.labelBold),
                Text(
                  isOut
                      ? 'In: $checkIn  ·  Out: $checkOut'
                      : 'Checked in at $checkIn',
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isOut
                  ? context.colors.textMuted.withValues(alpha: 0.1)
                  : context.colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              isOut ? 'Picked Up' : 'In Class',
              style: context.textStyles.caption.copyWith(
                color: isOut ? context.colors.textMuted : context.colors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
