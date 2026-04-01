import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/widgets/bottom_nav_bar.dart';
import 'package:tinysteps/core/widgets/logout_dialog.dart'; // ✅ ADDED

import 'package:tinysteps/features/parent/screens/my_children_screen.dart';
import 'package:tinysteps/features/parent/screens/parent_profile_screen.dart';
import 'package:tinysteps/features/parent/screens/attendance_history_screen.dart';
import 'package:tinysteps/features/parent/widgets/child_avatar.dart';
import 'package:tinysteps/features/parent/widgets/empty_state.dart';
import 'package:tinysteps/features/parent/widgets/qr_display_sheet.dart';

/// Parent Home Screen — shell with bottom navigation
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _ParentDashboard(),
    const MyChildrenScreen(),
    const AttendanceHistoryScreen(),
    const ParentProfileScreen(),
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
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavBarItem(icon: Icons.home_rounded, label: 'Home'),
            BottomNavBarItem(icon: Icons.face_rounded, label: 'Children'),
            BottomNavBarItem(icon: Icons.assignment_rounded, label: 'Attendance'),
            BottomNavBarItem(icon: Icons.settings_rounded, label: 'Account'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard tab — loads real children from DB
// ─────────────────────────────────────────────────────────────────────────────
class _ParentDashboard extends StatefulWidget {
  const _ParentDashboard();

  @override
  State<_ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<_ParentDashboard> {
  final _supabase = Supabase.instance.client;
  late Future<List<dynamic>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  void _loadChildren() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      _childrenFuture = Future.value([]);
      return;
    }

    _childrenFuture = _supabase
        .from('children')
        .select('id, full_name, status, qr_code')
        .eq('parent_id', uid);
  }

  // ✅ UPDATED LOGOUT WITH CONFIRMATION
  Future<void> _signOut() async {
    final confirmed = await showLogoutDialog(context);

    if (confirmed) {
      await _supabase.auth.signOut();
    }
  }

  Color _statusColor(String? status) => switch (status) {
        'checked_in' => AppColors.success,
        'checked_out' => AppColors.textMuted,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Parent';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('TinySteps', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut, // ✅ CONNECTED
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => setState(() => _loadChildren()),
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
              Text('Hello, $name 👋', style: AppTextStyles.heading1),
              Text(
                'Here\'s a quick look at your children today.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Your Children', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.md),

              FutureBuilder<List<dynamic>>(
                future: _childrenFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }

                  final children = snapshot.data ?? [];

                  if (children.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const EmptyState(
                        label: 'No children added yet.\nTap "Children" below to add your first child.',
                        icon: Icons.child_care_outlined,
                      ),
                    );
                  }

                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: children.map((c) {
                      final child = c as Map<String, dynamic>;
                      final childId = child['id'] as String;
                      final childName = child['full_name'] as String? ?? 'Child';
                      final status = child['status'] as String?;

                      return GestureDetector(
                        onTap: () => showQRDisplaySheet(
                          context,
                          childId: childId,
                          childName: childName,
                        ),
                        child: ChildAvatar(
                          name: childName,
                          status: _statusLabel(status),
                          color: _statusColor(status),
                          size: 60,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tap a child to show their check-in QR code',
                style: AppTextStyles.caption,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String? status) => switch (status) {
        'checked_in' => 'In Class',
        'checked_out' => 'Picked Up',
        _ => 'Enrolled',
      };
}