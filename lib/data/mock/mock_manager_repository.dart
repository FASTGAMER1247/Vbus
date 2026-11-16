import 'dart:async';
import 'dart:math';

import '../../core/models/compliance_models.dart';
import '../../core/models/driver_models.dart';
import '../../core/models/erp_models.dart';
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
  final List<DocumentAlert> _alerts = List.of(MockSeed.initialComplianceAlerts);

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
    final offlineBuses = activeBuses > 1 ? 1 : 0;
    final complianceWarnings = _alerts.where((a) => a.isExpired || a.isExpiringSoon).length;

    return FleetSummary(
      activeBuses: activeBuses,
      inactiveBuses: inactiveBuses,
      activeTrips: activeTrips,
      completedTrips: completedTrips,
      offlineBuses: offlineBuses,
      complianceWarningsCount: complianceWarnings,
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

  // --- Assignments (M1 Step 4) ---
  @override
  Future<List<FleetAssignment>> getAssignments(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_assignments);
  }

  @override
  Future<FleetAssignment> saveAssignment(FleetAssignment assignment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _assignments.indexWhere((a) => a.id == assignment.id);
    if (idx >= 0) {
      _assignments[idx] = assignment;
    } else {
      _assignments.add(assignment);
    }
    return assignment;
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _assignments.removeWhere((a) => a.id == assignmentId);
  }

  // --- Trip Management (M1 Step 5, M4, M5) ---
  @override
  Future<List<Trip>> getTrips(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_trips);
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _trips.where((t) => t.id == tripId).firstOrNull;
  }

  @override
  Future<Trip> createScheduledTrip(CreateTripParams params) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final bus = _buses.firstWhere((b) => b.id == params.busId, orElse: () => MockSeed.bus023);
    final driver = _drivers.firstWhere((d) => d.id == params.driverId, orElse: () => MockSeed.driverRamesh);
    final route = _routes.firstWhere((r) => r.id == params.routeId, orElse: () => MockSeed.route7);

    final trip = Trip(
      id: 'trip-scheduled-${DateTime.now().millisecondsSinceEpoch}',
      route: route,
      bus: bus,
      driver: driver,
      stage: TripStage.scheduled,
      startedAt: null,
    );

    _trips.add(trip);
    return trip;
  }

  @override
  Future<void> endStuckTrip({required String tripId, required String managerId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx >= 0) {
      _trips[idx] = _trips[idx].copyWith(
        stage: TripStage.endedManuallyByManager,
        completedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<DocumentAlert>> getComplianceAlerts(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return List.unmodifiable(_alerts);
  }

  // --- Live Fleet Telemetry Stream (M2, M3) ---
  @override
  Stream<List<FleetBusLocation>> watchFleetLocations(String collegeId) async* {
    var step = 0;
    while (true) {
      final list = <FleetBusLocation>[];

      for (var i = 0; i < _buses.length; i++) {
        final bus = _buses[i];
        final assign = _assignments.where((a) => a.busId == bus.id).firstOrNull;
        final driver = assign != null ? _drivers.where((d) => d.id == assign.driverId).firstOrNull : null;
        final route = assign != null ? _routes.where((r) => r.id == assign.routeId).firstOrNull : null;
        final activeTrip = _trips.where((t) => t.bus.id == bus.id && t.stage.isActive).firstOrNull;

        final busAlerts = _alerts.where((a) => a.entityId == bus.id).toList();

        if (activeTrip != null) {
          final stops = activeTrip.route.stops;
          final stopIdx = (step + i) % stops.length;
          final nextStopIdx = (stopIdx + 1) % stops.length;
          final s1 = stops[stopIdx];
          final s2 = stops[nextStopIdx];

          final frac = ((step % 10) / 10.0);
          final lat = s1.latitude + (s2.latitude - s1.latitude) * frac;
          final lng = s1.longitude + (s2.longitude - s1.longitude) * frac;

          final isOffline = (step + i) % 7 == 0;

          final loc = LiveLocation(
            latitude: lat,
            longitude: lng,
            speedKmh: isOffline ? 0 : 32.0,
            headingDegrees: 45.0,
            updatedAt: isOffline ? DateTime.now().subtract(const Duration(seconds: 75)) : DateTime.now(),
          );

          final health = DriverDeviceHealth(
            gps: isOffline ? GpsStatus.weak : GpsStatus.active,
            network: isOffline ? NetworkStatus.offline : NetworkStatus.online,
            batteryPercent: max(15, 85 - (step % 20)),
            lastSyncAt: DateTime.now(),
          );

          list.add(FleetBusLocation(
            bus: bus,
            route: route,
            driver: driver,
            activeTrip: activeTrip,
            location: loc,
            health: health,
            alerts: busAlerts,
          ));
        } else {
          list.add(FleetBusLocation(
            bus: bus,
            route: route,
            driver: driver,
            activeTrip: null,
            location: null,
            health: null,
            alerts: busAlerts,
          ));
        }
      }

      yield list;
      step++;
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  final List<ErpStudent> _students = [
    ErpStudent(
      id: 'stu-1',
      rollNumber: '21911A0542',
      name: 'K. Sai Charan',
      email: '21911a0542@vjit.ac.in',
      phone: '+91 98480 22334',
      department: 'Computer Science and Engineering',
      academicYear: '2025-26',
      section: 'CSE-B',
      routeId: 'route-7',
      routeName: 'Route 7 (Mehdipatnam - Campus)',
      stopName: 'Bharat Nagar',
      feeStatus: ErpFeeStatus.paid,
      feeAmount: 34000,
      paidAmount: 34000,
      receiptNumber: 'VJIT/REC/2025/08492',
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    ErpStudent(
      id: 'stu-2',
      rollNumber: '21911A0589',
      name: 'P. Rahul Reddy',
      email: '21911a0589@vjit.ac.in',
      phone: '+91 97001 44552',
      department: 'Information Technology',
      academicYear: '2025-26',
      section: 'IT-A',
      routeId: 'route-7',
      routeName: 'Route 7 (Mehdipatnam - Campus)',
      stopName: 'Central Silk Board',
      feeStatus: ErpFeeStatus.paid,
      feeAmount: 34000,
      paidAmount: 34000,
      receiptNumber: 'VJIT/REC/2025/08511',
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    ErpStudent(
      id: 'stu-3',
      rollNumber: '22911A0412',
      name: 'S. Ananya Sharma',
      email: '22911a0412@vjit.ac.in',
      phone: '+91 94412 88990',
      department: 'Electronics & Communication',
      academicYear: '2025-26',
      section: 'ECE-C',
      routeId: 'route-12',
      routeName: 'Route 12 (Kukatpally - Campus)',
      stopName: 'KPHB Colony',
      feeStatus: ErpFeeStatus.gracePeriod,
      feeAmount: 36000,
      paidAmount: 18000,
      receiptNumber: 'VJIT/REC/2025/09120',
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    ErpStudent(
      id: 'stu-4',
      rollNumber: '23911A0105',
      name: 'M. Vikram Kumar',
      email: '23911a0105@vjit.ac.in',
      phone: '+91 99882 11223',
      department: 'Civil Engineering',
      academicYear: '2025-26',
      section: 'CIVIL-A',
      routeId: 'route-7',
      routeName: 'Route 7 (Mehdipatnam - Campus)',
      stopName: 'BTM Layout',
      feeStatus: ErpFeeStatus.pending,
      feeAmount: 34000,
      paidAmount: 0,
      receiptNumber: null,
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    ErpStudent(
      id: 'stu-5',
      rollNumber: '22911A05F4',
      name: 'T. Sneha Patel',
      email: '22911a05f4@vjit.ac.in',
      phone: '+91 98845 66778',
      department: 'Computer Science and Engineering',
      academicYear: '2025-26',
      section: 'CSE-D',
      routeId: 'route-12',
      routeName: 'Route 12 (Kukatpally - Campus)',
      stopName: 'Miyapur Metro',
      feeStatus: ErpFeeStatus.overdue,
      feeAmount: 36000,
      paidAmount: 0,
      receiptNumber: null,
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  @override
  Future<ErpSyncResult> syncFromCollegeErp({
    required String collegeId,
    List<ErpStudent>? manualStudents,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (manualStudents != null && manualStudents.isNotEmpty) {
      for (final s in manualStudents) {
        final existingIdx = _students.indexWhere((x) => x.rollNumber == s.rollNumber);
        if (existingIdx >= 0) {
          _students[existingIdx] = s.copyWith(lastSyncedAt: DateTime.now());
        } else {
          _students.add(s.copyWith(lastSyncedAt: DateTime.now()));
        }
      }
    } else {
      for (var i = 0; i < _students.length; i++) {
        _students[i] = _students[i].copyWith(lastSyncedAt: DateTime.now());
      }
    }

    final paid = _students.where((s) => s.feeStatus == ErpFeeStatus.paid).length;
    final pending = _students.length - paid;

    return ErpSyncResult(
      totalFetched: _students.length,
      createdCount: manualStudents?.length ?? 0,
      updatedCount: _students.length,
      paidCount: paid,
      pendingCount: pending,
      provider: 'vmax College ERP',
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<List<ErpStudent>> getEnrolledStudents(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_students);
  }

  @override
  Future<void> updateStudentFeeStatus({
    required String collegeId,
    required String rollNumber,
    required ErpFeeStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _students.indexWhere((s) => s.rollNumber == rollNumber);
    if (idx >= 0) {
      _students[idx] = _students[idx].copyWith(
        feeStatus: status,
        lastSyncedAt: DateTime.now(),
      );
    }
  }
}
