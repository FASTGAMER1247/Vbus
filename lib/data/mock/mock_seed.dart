import '../../core/models/app_user.dart';
import '../../core/models/role.dart';
import '../../core/models/transport_models.dart';
import '../../core/models/trip_stage.dart';

/// Fake data standing in for the ERP + backend until they're wired up
/// (prd.md §15.4 / BACKEND_CHANGES.md). Coordinates are a straight
/// line near VJIT, Hyderabad — close enough for demo purposes, not
/// meant to be an accurate real-world route.
class MockSeed {
  MockSeed._();

  static const collegeId = 'college-vjit';
  static const collegeName = 'VJIT';

  static final stops = <Stop>[
    const Stop(id: 'stop-1', name: 'Ameerpet', latitude: 17.4374, longitude: 78.4487, order: 1, expectedTime: '7:15 AM'),
    const Stop(id: 'stop-2', name: 'SR Nagar', latitude: 17.4436, longitude: 78.4483, order: 2, expectedTime: '7:22 AM'),
    const Stop(id: 'stop-3', name: 'Balkampet', latitude: 17.4487, longitude: 78.4457, order: 3, expectedTime: '7:30 AM'),
    const Stop(id: 'stop-4', name: 'Bharat Nagar', latitude: 17.4540, longitude: 78.4430, order: 4, expectedTime: '7:38 AM'),
  ];

  static final route7 = TransportRoute(
    id: 'route-7',
    name: 'Route 7',
    stops: stops,
    estimatedDistanceKm: 12.4,
    expectedDuration: const Duration(hours: 1, minutes: 26),
  );

  static const bus023 = Bus(id: 'bus-023', busNumber: '023', registrationNumber: 'TS 09 AB 1234', capacity: 42);
  static const bus015 = Bus(id: 'bus-015', busNumber: '015', registrationNumber: 'TS 09 CD 5678', capacity: 50);
  static const bus042 = Bus(id: 'bus-042', busNumber: '042', registrationNumber: 'TS 09 EF 9012', capacity: 36);

  static const driverRamesh = DriverProfile(id: 'driver-1', name: 'Ramesh K', phone: '+91 90000 00001');
  static const driverSuresh = DriverProfile(id: 'driver-2', name: 'Suresh V', phone: '+91 90000 00002');
  static const driverAnand = DriverProfile(id: 'driver-3', name: 'Anand P', phone: '+91 90000 00003');

  static final route12Stops = <Stop>[
    const Stop(id: 'stop-12-1', name: 'Secunderabad Stn', latitude: 17.4334, longitude: 78.5044, order: 1, expectedTime: '7:10 AM'),
    const Stop(id: 'stop-12-2', name: 'Paradise', latitude: 17.4422, longitude: 78.4875, order: 2, expectedTime: '7:20 AM'),
    const Stop(id: 'stop-12-3', name: 'Begumpet', latitude: 17.4448, longitude: 78.4674, order: 3, expectedTime: '7:32 AM'),
  ];

  static final route12 = TransportRoute(
    id: 'route-12',
    name: 'Route 12 - Secunderabad',
    stops: route12Stops,
    estimatedDistanceKm: 18.2,
    expectedDuration: const Duration(hours: 1, minutes: 40),
  );

  static final initialBuses = <Bus>[bus023, bus015, bus042];
  static final initialDrivers = <DriverProfile>[driverRamesh, driverSuresh, driverAnand];
  static final initialRoutes = <TransportRoute>[route7, route12];

  // ---- Demo accounts, one per role ----
  static const studentUser = AppUser(
    id: 'user-student-1',
    name: 'Sanjay',
    role: UserRole.student,
    collegeId: collegeId,
    collegeName: collegeName,
  );

  static const facultyUser = AppUser(
    id: 'user-faculty-1',
    name: 'Dr. Meera Rao',
    role: UserRole.faculty,
    collegeId: collegeId,
    collegeName: collegeName,
  );

  static const driverUser = AppUser(
    id: 'user-driver-1',
    name: 'Ramesh K',
    role: UserRole.driver,
    collegeId: collegeId,
    collegeName: collegeName,
  );

  static const managerUser = AppUser(
    id: 'user-manager-1',
    name: 'Priya Nair',
    role: UserRole.manager,
    collegeId: collegeId,
    collegeName: collegeName,
  );

  static const masterAdminUser = AppUser(
    id: 'user-admin-1',
    name: 'Platform Admin',
    role: UserRole.masterAdmin,
    collegeId: collegeId,
    collegeName: collegeName,
  );

  static List<AppUser> get allDemoUsers =>
      [studentUser, facultyUser, driverUser, managerUser, masterAdminUser];

  static Trip activeTrip() => Trip(
        id: 'trip-today-1',
        route: route7,
        bus: bus023,
        driver: driverRamesh,
        stage: TripStage.onRoute,
        startedAt: DateTime.now().subtract(const Duration(minutes: 18)),
        lastLocation: LiveLocation(
          latitude: stops[1].latitude,
          longitude: stops[1].longitude,
          speedKmh: 28,
          headingDegrees: 40,
          updatedAt: DateTime.now(),
        ),
      );

  /// flow.md D1: the driver flow starts from a trip that already
  /// exists as `scheduled` (see BACKEND_CHANGES.md #5 — nothing
  /// creates this automatically yet, a manager has to). This is that
  /// trip, for the driver demo account.
  static Trip todayScheduledTrip() => Trip(
        id: 'trip-scheduled-1',
        route: route7,
        bus: bus023,
        driver: driverRamesh,
        stage: TripStage.scheduled,
      );

  /// Demo Bus IDs for exercising every D5 blocked-start reason without
  /// needing real backend data. '023' is the only one that succeeds.
  static const demoBusOutcomes = <String, String>{
    '023': 'ok',
    '999': 'not_found',
    '011': 'another_college',
    '007': 'not_assigned',
    '023-busy': 'already_active', // typed as-is to demo this branch
  };
}
