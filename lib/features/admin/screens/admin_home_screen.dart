import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_theme.dart';


import 'floating_nav_bar.dart';
import 'users_screen.dart';


/// Admin Home Screen — Squad D's home base
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  //NEW: track current tab index
  int _currentIndex = 0;

  // NEW: list of tabs
  final List<Widget> _tabs = const [
    // Tab 1 — your original Admin dashboard content
    _AdminDashboardContent(),

    // Tab 2 — Users management
    UsersScreen(),

  ];

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      // GoRouter _SupabaseAuthNotifier will handle redirect to /login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: buildFloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}


class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Admin Panel', style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
<<<<<<< HEAD
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
=======
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
>>>>>>> c1c4a40fd8042d3a6fc2d3d513a1734b2962c04f
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Control Panel', style: AppTextStyles.heading1),
            Text('Manage staff, users, and classrooms',
                style: AppTextStyles.bodyMuted),
            const SizedBox(height: AppSpacing.xl),

            // Stat cards row
            Row(
              children: [
                _StatCard(
                  label: 'Total Users',
                  value: '124',
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                _StatCard(
                  label: 'Waitlist',
                  value: '12',
                  icon: Icons.pending_actions,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Quick Actions', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),

            ListTile(
              leading: const Icon(Icons.how_to_reg, color: AppColors.primary),
              title: const Text('Approve Staff Accounts'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {/* TODO: navigate to approval list */},
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              tileColor: AppColors.white,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.class_, color: AppColors.secondary),
              title: const Text('Manage Classrooms'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {/* TODO: navigate to classroom list */},
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              tileColor: AppColors.white,
            ),
          ],
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
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
                style: AppTextStyles.heading1.copyWith(color: color)),
            Text(label, style: AppTextStyles.bodyMuted),
          ],
        ),
      ),
    );
  }
}