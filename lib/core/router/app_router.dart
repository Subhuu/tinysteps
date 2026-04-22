import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tinysteps/features/auth/screens/login_screen.dart';
import 'package:tinysteps/features/auth/screens/register_screen.dart';
import 'package:tinysteps/features/parent/screens/parent_home_screen.dart';
import 'package:tinysteps/features/parent/screens/my_children_screen.dart';
import 'package:tinysteps/features/parent/screens/add_child_screen.dart';
import 'package:tinysteps/features/parent/screens/child_profile_screen.dart';
import 'package:tinysteps/core/screens/notifications_screen.dart';
import 'package:tinysteps/core/screens/support_screen.dart';
import 'package:tinysteps/core/screens/app_settings_screen.dart';
import 'package:tinysteps/core/screens/about_app_screen.dart';
import 'package:tinysteps/core/screens/change_password_screen.dart';
import 'package:tinysteps/features/parent/screens/attendance_history_screen.dart';
import 'package:tinysteps/features/teacher/screens/teacher_home_screen.dart';
import 'package:tinysteps/features/teacher/screens/attendance_screen.dart';
import 'package:tinysteps/features/teacher/screens/child_detail_screen.dart';
import 'package:tinysteps/features/teacher/screens/my_classroom_screen.dart';
import 'package:tinysteps/features/admin/screens/admin_home_screen.dart';
import 'package:tinysteps/features/admin/screens/privacy_policy_screen.dart';

import '../../features/teacher/screens/teacher_faq_screen.dart';

// ── Listens to Supabase auth state and notifies GoRouter to re-evaluate ──────
class _SupabaseAuthNotifier extends ChangeNotifier {
  _SupabaseAuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _SupabaseAuthNotifier();

// ── Helper: role → route ──────────────────────────────────────────────────────
String _routeForRole(String? role) => switch (role) {
  'teacher' => '/teacher',
  'admin' => '/admin',
  _ => '/parent',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final loc = state.matchedLocation;
      final isOnAuth = loc == '/login' || loc == '/register';

      if (!isLoggedIn && !isOnAuth) return '/login';

      if (isLoggedIn && isOnAuth) {
        final role = session.user.userMetadata?['role'] as String?;
        return _routeForRole(role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),

      // ── Parent ──────────────────────────────────────────────────────────────
      GoRoute(path: '/parent', builder: (c, s) => const ParentHomeScreen()),
      GoRoute(
        path: '/parent/children',
        builder: (c, s) => const MyChildrenScreen(),
      ),
      GoRoute(
        path: '/parent/children/add',
        builder: (c, s) => const AddChildScreen(),
      ),
      GoRoute(
        path: '/parent/children/:childId',
        builder: (c, s) => ChildProfileScreen(
          childId: s.pathParameters['childId']!,
          childName: s.uri.queryParameters['name'] ?? '',
        ),
      ),

      // ── Shared Settings Hub Routes ──────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (c, s) => const NotificationsScreen(),
      ),
      GoRoute(path: '/support', builder: (c, s) => const SupportScreen()),
      GoRoute(
        path: '/app-settings',
        builder: (c, s) => const AppSettingsScreen(),
      ),
      GoRoute(path: '/about', builder: (c, s) => const AboutAppScreen()),
      GoRoute(
        path: '/change-password',
        builder: (c, s) => const ChangePasswordScreen(),
      ),

      // ✅ ADDED THIS 👇
      GoRoute(
        path: '/privacy-policy',
        builder: (c, s) => const PrivacyPolicyScreen(),
      ),

      GoRoute(
        path: '/parent/attendance',
        builder: (c, s) => const AttendanceHistoryScreen(),
      ),

      // ── Teacher ─────────────────────────────────────────────────────────────
      GoRoute(path: '/teacher', builder: (c, s) => const TeacherHomeScreen()),
      GoRoute(
        path: '/teacher/attendance',
        builder: (c, s) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/teacher/classroom',
        builder: (c, s) => const MyClassroomScreen(),
      ),
      GoRoute(
        path: '/teacher/child/:childId',
        builder: (c, s) => ChildDetailScreen(
          childId: s.pathParameters['childId']!,
          childName: s.uri.queryParameters['name'] ?? 'Child',
        ),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) => const TeacherFAQScreen(),
      ),

      // ── Admin ────────────────────────────────────────────────────────────────
      GoRoute(path: '/admin', builder: (c, s) => const AdminHomeScreen()),
    ],
  );
});
