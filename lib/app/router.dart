import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/role.dart';
import '../features/driver/active_trip_screen.dart';
import '../features/driver/driver_home_screen.dart';
import '../features/driver/identify_bus_screen.dart';
import '../features/driver/permission_onboarding_screen.dart';
import '../features/driver/trip_completed_screen.dart';
import '../features/driver/trip_confirmation_screen.dart';
import '../features/manager/assignment_screen.dart';
import '../features/manager/bus_form_screen.dart';
import '../features/manager/bus_list_screen.dart';
import '../features/manager/create_trip_screen.dart';
import '../features/manager/driver_form_screen.dart';
import '../features/manager/driver_list_screen.dart';
import '../features/manager/manager_home_screen.dart';
import '../features/manager/manager_live_fleet_screen.dart';
import '../features/manager/manager_trip_list_screen.dart';
import '../features/manager/route_builder_screen.dart';
import '../features/manager/route_list_screen.dart';
import '../features/manager/trip_summary_screen.dart';
import '../features/master_admin/college_detail_screen.dart';
import '../features/master_admin/college_form_screen.dart';
import '../features/master_admin/college_list_screen.dart';
import '../features/master_admin/manager_form_screen.dart';
import '../features/master_admin/manager_list_screen.dart';
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

      // Manager (M1–M5)
      GoRoute(path: '/manager', builder: (context, state) => const ManagerHomeScreen()),
      GoRoute(path: '/manager/fleet', builder: (context, state) => const ManagerLiveFleetScreen()),
      GoRoute(path: '/manager/buses', builder: (context, state) => const BusListScreen()),
      GoRoute(path: '/manager/buses/new', builder: (context, state) => const BusFormScreen()),
      GoRoute(path: '/manager/drivers', builder: (context, state) => const DriverListScreen()),
      GoRoute(path: '/manager/drivers/new', builder: (context, state) => const DriverFormScreen()),
      GoRoute(path: '/manager/routes', builder: (context, state) => const RouteListScreen()),
      GoRoute(path: '/manager/routes/new', builder: (context, state) => const RouteBuilderScreen()),
      GoRoute(path: '/manager/assignments', builder: (context, state) => const AssignmentScreen()),
      GoRoute(path: '/manager/trips', builder: (context, state) => const ManagerTripListScreen()),
      GoRoute(path: '/manager/trips/new', builder: (context, state) => const CreateTripScreen()),
      GoRoute(
        path: '/manager/trips/:id',
        builder: (context, state) => TripSummaryScreen(tripId: state.pathParameters['id'] ?? ''),
      ),

      // Master Admin (A1–A3)
      GoRoute(path: '/admin', builder: (context, state) => const MasterAdminHomeScreen()),
      GoRoute(path: '/admin/colleges', builder: (context, state) => const CollegeListScreen()),
      GoRoute(path: '/admin/colleges/new', builder: (context, state) => const CollegeFormScreen()),
      GoRoute(
        path: '/admin/colleges/:id',
        builder: (context, state) => CollegeDetailScreen(collegeId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/admin/colleges/:id/edit',
        builder: (context, state) => CollegeFormScreen(collegeId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/colleges/:id/managers/new',
        builder: (context, state) => AdminManagerFormScreen(initialCollegeId: state.pathParameters['id']),
      ),
      GoRoute(path: '/admin/managers', builder: (context, state) => const AdminManagerListScreen()),
      GoRoute(path: '/admin/managers/new', builder: (context, state) => const AdminManagerFormScreen()),
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
