import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../widgets/child_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/qr_display_sheet.dart';

/// Parent Home Screen — with bottom navigation
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _ParentDashboard(),
    const _PlaceholderScreen(title: 'My Children', icon: Icons.face_rounded),
    const _PlaceholderScreen(title: 'Attendance', icon: Icons.assignment_rounded),
    const _PlaceholderScreen(title: 'Account', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard tab (was the old ParentHomeScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _ParentDashboard extends StatelessWidget {
  const _ParentDashboard();

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
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
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text('Hello, $name 👋', style: AppTextStyles.heading1),
            Text('Your children are doing great today!', style: AppTextStyles.bodyMuted),
            const SizedBox(height: AppSpacing.lg),

            // Children List
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: const [
                ChildAvatar(name: 'Leo', status: 'In Class', color: Colors.blue, size: 60),
                ChildAvatar(name: 'Mia', status: 'Checked Out', color: Colors.orange, size: 60),
                ChildAvatar(name: 'S', status: 'Large Demo', color: Colors.purple, size: 80),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xl),
            Text('Quick Actions', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),

            // Quick-action cards
            _QuickActionCard(
              icon: Icons.qr_code,
              label: 'Show My QR Code',
              color: AppColors.secondary,
              onTap: () => showQRDisplaySheet(
                context,
                childId: 'dummy-child-001',
                childName: 'Leo Smith',
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Quick Examples (Squad B)', style: AppTextStyles.labelBold.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.md),
            
            // Status Badges
            Text('Status Badges:', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            const Wrap(
              spacing: AppSpacing.sm,
              children: [
                StatusChip(status: 'Checked In'),
                StatusChip(status: 'At Home'),
                StatusChip(status: 'Checked Out'),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Empty State for messages
            Text('Empty Messages List:', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const EmptyState(
                label: 'No messages yet.\nCheck back later for teacher updates!',
                icon: Icons.forum_outlined,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Empty State for calendar
            Text('Empty Calendar:', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const EmptyState(
                label: 'No events scheduled for this week.',
                icon: Icons.event_busy_outlined,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder screens for other tabs
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.heading2),
        backgroundColor: AppColors.bgLight,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('$title Coming Soon...', style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick action card widget
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTextStyles.heading2),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}
