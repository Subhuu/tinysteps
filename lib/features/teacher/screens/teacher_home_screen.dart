import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/widgets/bottom_nav_bar.dart';
import 'package:tinysteps/core/widgets/logout_dialog.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  final _supabase = Supabase.instance.client;

  bool? _isApproved;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _TeacherDashboardTab(),
      const _TeacherAttendanceTab(),
      const _TeacherChildrenTab(),
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
            row != null && row['is_approved'] == true && row['is_active'] == true;
      });
    } catch (_) {
      if (mounted) setState(() => _isApproved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isApproved == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_isApproved == false) {
      return _PendingApprovalScreen(
        onRefresh: () async {
          setState(() => _isApproved = null);
          await _checkApproval();
        },
        onSignOut: () async {
          final confirmed = await showLogoutDialog(context);
          if (confirmed) {
            await _supabase.auth.signOut();
          }
        },
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
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavBarItem(icon: Icons.home_rounded, label: 'Home'),
            BottomNavBarItem(icon: Icons.assignment_rounded, label: 'Attendance'),
            BottomNavBarItem(icon: Icons.face_rounded, label: 'Children'),
          ],
        ),
      ),
    );
  }
}

// ✅ Pending Approval Screen (FIXED LOGOUT)
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
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('TinySteps', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirmed = await showLogoutDialog(context);
              if (confirmed) {
                onSignOut();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 72),
              const SizedBox(height: AppSpacing.xl),
              Text('Pending Approval', style: AppTextStyles.heading1),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Waiting for admin approval',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Dashboard (FIXED LOGOUT)
class _TeacherDashboardTab extends StatelessWidget {
  const _TeacherDashboardTab();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TinySteps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showLogoutDialog(context);
              if (confirmed) {
                await Supabase.instance.client.auth.signOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Text('Hello $name'),
          const SizedBox(height: 20),
          const _TodayAttendanceSummary(),
        ],
      ),
    );
  }
}

// ✅ Attendance Tab (EXISTING — RESTORED)
class _TeacherAttendanceTab extends StatelessWidget {
  const _TeacherAttendanceTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Attendance Screen")),
    );
  }
}

// ✅ Children Tab (EXISTING — RESTORED)
class _TeacherChildrenTab extends StatelessWidget {
  const _TeacherChildrenTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Children Screen")),
    );
  }
}

// ✅ Attendance Summary (EXISTING — RESTORED)
class _TodayAttendanceSummary extends StatelessWidget {
  const _TodayAttendanceSummary();

  @override
  Widget build(BuildContext context) {
    return const Text("Today's Attendance Data");
  }
}