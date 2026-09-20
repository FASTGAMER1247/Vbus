import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/manager_models.dart';
import '../../core/models/transport_models.dart';

/// Metric summary for the dashboard cards (flow.md M2).
final fleetSummaryProvider = FutureProvider.autoDispose<FleetSummary>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getFleetSummary(collegeId);
});

/// List of all buses belonging to the manager's college (M1 Step 1).
final busesProvider = FutureProvider.autoDispose<List<Bus>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getBuses(collegeId);
});

/// List of all drivers belonging to the manager's college (M1 Step 2).
final driversProvider = FutureProvider.autoDispose<List<DriverProfile>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getDrivers(collegeId);
});

/// List of all routes belonging to the manager's college (M1 Step 3).
final routesProvider = FutureProvider.autoDispose<List<TransportRoute>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getRoutes(collegeId);
});

/// List of active Driver <-> Bus <-> Route assignments (M1 Step 4).
final assignmentsProvider = FutureProvider.autoDispose<List<FleetAssignment>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getAssignments(collegeId);
});

/// List of all trips (scheduled, active, completed) (M1 Step 5, M4).
final tripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getTrips(collegeId);
});

/// Single trip lookup for summary review and resolution (M4, M5).
final tripDetailProvider = FutureProvider.family.autoDispose<Trip?, String>((ref, tripId) {
  return ref.watch(managerRepositoryProvider).getTripById(tripId);
});

/// Real-time live fleet stream powering the manager fleet map (M2, M3).
final liveFleetLocationsProvider = StreamProvider.autoDispose<List<FleetBusLocation>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).watchFleetLocations(collegeId);
});
