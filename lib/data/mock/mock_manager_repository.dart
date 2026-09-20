import 'dart:async';
import 'dart:math';

import '../../core/models/driver_models.dart';
import '../../core/models/manager_models.dart';
import '../../core/models/transport_models.dart';
import '../../core/models/trip_stage.dart';
import '../repositories/manager_repository.dart';
import 'mock_seed.dart';

/// Mock implementation of [ManagerRepository] (flow.md M1–M5, prd.md Modules 4–7, 11, 13).
class MockManagerRepository implements ManagerRepository {
  final List<Bus> _buses = List.of(MockSeed.initialBuses);
  final List<DriverProfile> _drivers = List.of(MockSeed.initialDrivers);
  final List<TransportRoute> _routes = List.of(MockSeed.initialRoutes);
  final List<FleetAssignment> _assignments = [
    FleetAssignment(
      id: 'assign-1',
      collegeId: MockSeed.collegeId,
      busId: MockSeed.bus023.id,
      driverId: MockSeed.driverRamesh.id,
      routeId: MockSeed.route7.id,
      assignedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    FleetAssignment(
      id: 'assign-2',
      collegeId: MockSeed.collegeId,
      busId: MockSeed.bus015.id,
      driverId: MockSeed.driverSuresh.id,
      routeId: MockSeed.route12.id,
      assignedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  final List<Trip> _trips = [
    MockSeed.activeTrip(),
    Trip(
      id: 'trip-completed-yesterday',
      route: MockSeed.route7,
      bus: MockSeed.bus023,
      driver: MockSeed.driverRamesh,
      stage: TripStage.completed,
      startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    ),
    Trip(
      id: 'trip-scheduled-2',
      route: MockSeed.route12,
      bus: MockSeed.bus015,
      driver: MockSeed.driverSuresh,
      stage: TripStage.scheduled,
      startedAt: null,
    ),
  ];

  @override
  Future<FleetSummary> getFleetSummary(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final activeTrips = _trips.where((t) => t.stage.isActive).length;
    final completedTrips = _trips.where((t) => t.stage == TripStage.completed).length;
    final activeBusIds = _trips.where((t) => t.stage.isActive).map((t) => t.bus.id).toSet();
    final activeBuses = activeBusIds.length;
    final inactiveBuses = max(0, _buses.length - activeBuses);
    // Simulate 1 offline bus if any active
    final offlineBuses = activeBuses > 1 ? 1 : 0;

    return FleetSummary(
      activeBuses: activeBuses,
      inactiveBuses: inactiveBuses,
      activeTrips: activeTrips,
      completedTrips: completedTrips,
      offlineBuses: offlineBuses,
    );
  }

  // --- Buses CRUD (M1 Step 1) ---
  @override
  Future<List<Bus>> getBuses(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_buses);
  }

  @override
  Future<Bus> saveBus({required String collegeId, required Bus bus}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _buses.indexWhere((b) => b.id == bus.id);
    if (idx >= 0) {
      _buses[idx] = bus;
    } else {
      _buses.add(bus);
    }
    return bus;
  }

  @override
  Future<void> deleteBus(String busId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _buses.removeWhere((b) => b.id == busId);
    _assignments.removeWhere((a) => a.busId == busId);
  }

  // --- Drivers CRUD (M1 Step 2) ---
  @override
  Future<List<DriverProfile>> getDrivers(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_drivers);
  }

  @override
  Future<DriverProfile> saveDriver({required String collegeId, required DriverProfile driver}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _drivers.indexWhere((d) => d.id == driver.id);
    if (idx >= 0) {
      _drivers[idx] = driver;
    } else {
      _drivers.add(driver);
    }
    return driver;
  }

  @override
  Future<void> deleteDriver(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _drivers.removeWhere((d) => d.id == driverId);
    _assignments.removeWhere((a) => a.driverId == driverId);
  }

  // --- Routes CRUD (M1 Step 3) ---
  @override
  Future<List<TransportRoute>> getRoutes(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_routes);
  }

  @override
  Future<TransportRoute> saveRoute({required String collegeId, required TransportRoute route}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _routes.indexWhere((r) => r.id == route.id);
    if (idx >= 0) {
      _routes[idx] = route;
    } else {
      _routes.add(route);
    }
    return route;
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _routes.removeWhere((r) => r.id == routeId);
    _assignments.removeWhere((a) => a.routeId == routeId);
  }

  // --- Assignments CRUD (M1 Step 4) ---
  @override
  Future<List<FleetAssignment>> getAssignments(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_assignments);
  }

  @override
  Future<FleetAssignment> saveAssignment(FleetAssignment assignment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Rule: only one assignment per bus
    _assignments.removeWhere((a) => a.busId == assignment.busId);
    _assignments.add(assignment);
    return assignment;
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _assignments.removeWhere((a) => a.id == assignmentId);
  }

  // --- Trips & Reports (M1 Step 5, M4, M5) ---
  @override
  Future<List<Trip>> getTrips(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_trips);
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _trips.firstWhere((t) => t.id == tripId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Trip> createScheduledTrip(CreateTripParams params) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final bus = _buses.firstWhere((b) => b.id == params.busId);
    final driver = _drivers.firstWhere((d) => d.id == params.driverId);
    final route = _routes.firstWhere((r) => r.id == params.routeId);

    final trip = Trip(
      id: 'trip-sched-${DateTime.now().millisecondsSinceEpoch}',
      route: route,
      bus: bus,
      driver: driver,
      stage: TripStage.scheduled,
    );
    _trips.insert(0, trip);
    return trip;
  }

  @override
  Future<void> endStuckTrip({required String tripId, required String managerId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx >= 0) {
      final trip = _trips[idx];
      _trips[idx] = trip.copyWith(
        stage: TripStage.endedManuallyByManager,
        completedAt: DateTime.now(),
      );
    }
  }

  // --- Live Fleet Monitoring (M2, M3) ---
  @override
  Stream<List<FleetBusLocation>> watchFleetLocations(String collegeId) async* {
    var step = 0;
    while (true) {
      final list = <FleetBusLocation>[];

      for (final bus in _buses) {
        final assignment = _assignments.cast<FleetAssignment?>().firstWhere(
              (a) => a?.busId == bus.id,
              orElse: () => null,
            );
        final driver = assignment != null
            ? _drivers.cast<DriverProfile?>().firstWhere(
                  (d) => d?.id == assignment.driverId,
                  orElse: () => null,
                )
            : null;
        final route = assignment != null
            ? _routes.cast<TransportRoute?>().firstWhere(
                  (r) => r?.id == assignment.routeId,
                  orElse: () => null,
                )
            : null;

        final activeTrip = _trips.cast<Trip?>().firstWhere(
              (t) => t != null && t.bus.id == bus.id && t.stage.isActive,
              orElse: () => null,
            );

        if (activeTrip != null && route != null && route.stops.isNotEmpty) {
          final stops = route.stops;
          final int idx = (step ~/ 5) % max<int>(1, stops.length - 1);
          final int nextIdx = (idx + 1) % stops.length;
          final t = (step % 5) / 5.0;

          final lat = stops[idx].latitude + (stops[nextIdx].latitude - stops[idx].latitude) * t;
          final lng = stops[idx].longitude + (stops[nextIdx].longitude - stops[idx].longitude) * t;

          final loc = LiveLocation(
            latitude: lat,
            longitude: lng,
            speedKmh: 32 + (step % 4) * 3.0,
            headingDegrees: 45,
            updatedAt: DateTime.now(),
          );

          final health = DriverDeviceHealth(
            gps: GpsStatus.active,
            network: NetworkStatus.online,
            batteryPercent: max<int>(20, 88 - (step ~/ 2)),
            lastSyncAt: DateTime.now(),
          );

          list.add(FleetBusLocation(
            bus: bus,
            route: route,
            driver: driver,
            activeTrip: activeTrip,
            location: loc,
            health: health,
          ));
        } else {
          list.add(FleetBusLocation(
            bus: bus,
            route: route,
            driver: driver,
            activeTrip: null,
            location: null,
            health: null,
          ));
        }
      }

      yield list;
      step++;
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}
