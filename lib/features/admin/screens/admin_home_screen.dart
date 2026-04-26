import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/widgets/bottom_nav_bar.dart';
import 'package:tinysteps/features/admin/screens/users_screen.dart';
import 'package:tinysteps/features/admin/screens/classrooms_screen.dart';
import 'package:tinysteps/features/admin/screens/children_overview_screen.dart';
import 'package:tinysteps/features/admin/screens/admin_settings_screen.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

/// Admin Home Screen — shell with bottom navigation
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    const _AdminDashboardContent(),
    const UsersScreen(),
    const ClassroomsScreen(),
    const ChildrenOverviewScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavBarItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
            BottomNavBarItem(icon: Icons.people_rounded, label: 'Users'),
            BottomNavBarItem(icon: Icons.class_rounded, label: 'Classrooms'),
            BottomNavBarItem(icon: Icons.child_care_rounded, label: 'Children'),
            BottomNavBarItem(icon: Icons.settings_rounded, label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard tab with Greeting Card + Live Stats
// ─────────────────────────────────────────────────────────────────────────────
class _AdminDashboardContent extends StatefulWidget {
  const _AdminDashboardContent();

  @override
  State<_AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<_AdminDashboardContent> {
  final _supabase = Supabase.instance.client;
  late Future<Map<String, int>> _statsFuture;

  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _loadStats();

    // Update greeting every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  void _loadStats() {
    _statsFuture = _supabase.rpc('admin_dashboard_stats').then((result) {
      final data = result as Map<String, dynamic>;
      return {
        'teachers': (data['teachers'] as num?)?.toInt() ?? 0,
        'pendingTeachers': (data['pendingTeachers'] as num?)?.toInt() ?? 0,
        'parents': (data['parents'] as num?)?.toInt() ?? 0,
        'children': (data['children'] as num?)?.toInt() ?? 0,
        'classrooms': (data['classrooms'] as num?)?.toInt() ?? 0,
        'unassigned': (data['unassigned'] as num?)?.toInt() ?? 0,
      };
    });
  }

  String _getGreeting() {
    final hour = _now.hour;
    if (hour >= 5 && hour < 12) return 'Good morning 🌅';
    if (hour >= 12 && hour < 15) return 'Good afternoon ☀️';
    if (hour >= 15 && hour < 18) return 'Good evening 🌇';
    return 'Good night 🌙';
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgLight,
        surfaceTintColor: Colors.transparent,
        title: Text('Sign out?', style: context.textStyles.heading3),
        content: Text('You will be returned to the login screen.',
            style: context.textStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: context.textStyles.labelBold
                    .copyWith(color: context.colors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out', style: context.textStyles.buttonLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _supabase.auth.signOut();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Admin';

    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text('Admin Panel', style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async => setState(() => _loadStats()),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl + 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= GREETING CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: AppGradients.sunrise, // Make sure this exists in app_theme.dart
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.card, // Make sure this exists
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _getGreeting(),
                      style: context.textStyles.bodyLarge.copyWith(
                        color: context.colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      name,
                      style: context.textStyles.heading1.copyWith(
                        color: context.colors.white,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text('Here\'s your daycare at a glance',
                  style: context.textStyles.bodyMuted),

              const SizedBox(height: AppSpacing.xl),

              // ── Stats Grid ──────────────────────────────────────────
              FutureBuilder<Map<String, int>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(
                            color: context.colors.primary),
                      ),
                    );
                  }

                  final stats = snapshot.data ??
                      {
                        'teachers': 0,
                        'pendingTeachers': 0,
                        'parents': 0,
                        'children': 0,
                        'classrooms': 0,
                        'unassigned': 0,
                      };

                  return Column(
                    children: [
                      Row(
                        children: [
                          _StatCard(
                            label: 'Teachers',
                            value: '${stats['teachers']}',
                            icon: Icons.school,
                            color: context.colors.primary,
                            onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const UsersScreen())),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _StatCard(
                            label: 'Pending Approval',
                            value: '${stats['pendingTeachers']}',
                            icon: Icons.pending_actions,
                            color: context.colors.warning,
                            onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const UsersScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _StatCard(
                            label: 'Parents',
                            value: '${stats['parents']}',
                            icon: Icons.family_restroom,
                            color: context.colors.secondary,
                            onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const UsersScreen())),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _StatCard(
                            label: 'Children',
                            value: '${stats['children']}',
                            icon: Icons.child_care,
                            color: context.colors.accent,
                            onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const ChildrenOverviewScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _StatCard(
                            label: 'Classrooms',
                            value: '${stats['classrooms']}',
                            icon: Icons.class_,
                            color: context.colors.success,
                            onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const ClassroomsScreen())),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _StatCard(
                            label: 'Unassigned',
                            value: '${stats['unassigned']}',
                            icon: Icons.warning_amber,
                            color: context.colors.danger,
                            onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const UsersScreen())),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final VoidCallback? onTap;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(value,
                  style: context.textStyles.heading1.copyWith(color: color)),
              Text(label, style: context.textStyles.bodyMuted),
            ],
          ),
        ),
      ),
    );
  }
}
