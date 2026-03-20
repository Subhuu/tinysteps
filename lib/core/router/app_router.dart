import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/parent/screens/parent_home_screen.dart';
import '../../features/teacher/screens/teacher_home_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isOnAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isOnAuth) return '/login';
      if (isLoggedIn && isOnAuth) {
        // Role-based redirect after login
        final role =
            session.user.userMetadata?['role'] as String? ?? 'parent';
        return switch (role) {
          'teacher' => '/teacher',
          'admin' => '/admin',
          _ => '/parent',
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/parent', builder: (c, s) => const ParentHomeScreen()),
      GoRoute(path: '/teacher', builder: (c, s) => const TeacherHomeScreen()),
      GoRoute(path: '/admin', builder: (c, s) => const AdminHomeScreen()),
    ],
  );
});
