import 'package:flutter/material.dart';
import 'package:tinysteps/core/widgets/bottom_nav_bar.dart';
import 'package:tinysteps/features/parent/screens/parent_profile_screen.dart';
import 'package:tinysteps/features/parent/screens/feed_screen.dart';
import 'package:tinysteps/features/parent/screens/safety_screen.dart';
import 'package:tinysteps/features/parent/screens/analytics_screen.dart';

/// Parent Home Screen — shell with bottom navigation
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const SafetyScreen(),
    const AnalyticsScreen(),
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
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavBarItem(icon: Icons.assignment_rounded, label: 'Feed'),
            BottomNavBarItem(icon: Icons.videocam_rounded, label: 'Safety'),
            BottomNavBarItem(icon: Icons.insights_rounded, label: 'Analytics'),
            BottomNavBarItem(icon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
