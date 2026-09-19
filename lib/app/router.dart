import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/role.dart';
import '../features/driver/active_trip_screen.dart';
import '../features/driver/driver_home_screen.dart';
import '../features/driver/identify_bus_screen.dart';
import '../features/driver/permission_onboarding_screen.dart';
import '../features/driver/trip_completed_screen.dart';
import '../features/driver/trip_confirmation_screen.dart';
import '../features/manager/manager_home_screen.dart';
import '../features/master_admin/master_admin_home_screen.dart';
import '../features/student/login_screen.dart';
import '../features/student/student_home_screen.dart';
import '../features/student/student_live_map_screen.dart';
import '../features/student/student_route_screen.dart';
import 'providers.dart';

/// flow.md C1 (login gate) + C2 (role routing) in one place. Each
/// role's screens only ever live under their own path prefix — a
/// student can never navigate into /manager/*, even by typing the URL
/// on web, because the redirect below catches it on every navigation.
final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      if (user == null) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        return user.role.homeRoute; // C2: send to the role's home
      }

      final allowedPrefix = _prefixFor(user.role);
      if (!state.matchedLocation.startsWith(allowedPrefix)) {
        return user.role.homeRoute;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Student / Faculty (S1–S4 in flow.md)
      GoRoute(path: '/student', builder: (context, state) => const StudentHomeScreen()),
      GoRoute(path: '/student/live', builder: (context, state) => const StudentLiveMapScreen()),
      GoRoute(path: '/student/route', builder: (context, state) => const StudentRouteScreen()),

      // Driver (D1–D5) — built out; D1 permission gate lives in
      // DriverHomeScreen.build, before pushing to /driver/identify
      GoRoute(path: '/driver', builder: (context, state) => const DriverHomeScreen()),
      GoRoute(path: '/driver/permissions', builder: (context, state) => const PermissionOnboardingScreen()),
      GoRoute(path: '/driver/identify', builder: (context, state) => const IdentifyBusScreen()),
      GoRoute(path: '/driver/confirm', builder: (context, state) => const TripConfirmationScreen()),
      GoRoute(path: '/driver/active', builder: (context, state) => const ActiveTripScreen()),
      GoRoute(path: '/driver/completed', builder: (context, state) => const TripCompletedScreen()),

      // Manager (M1–M5) — stub for now, built next
      GoRoute(path: '/manager', builder: (context, state) => const ManagerHomeScreen()),

      // Master Admin (A1–A3) — stub for now, built next
      GoRoute(path: '/admin', builder: (context, state) => const MasterAdminHomeScreen()),
    ],
  );
});

String _prefixFor(UserRole role) {
  switch (role) {
    case UserRole.student:
    case UserRole.faculty:
      return '/student';
    case UserRole.driver:
      return '/driver';
    case UserRole.manager:
      return '/manager';
    case UserRole.masterAdmin:
      return '/admin';
  }
}
