import 'trip_stage.dart';

/// prd.md §2 Glossary — "Stop: a pickup or drop point on a route."
class Stop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;
  final String? expectedTime; // "7:42 AM" — display string, [Later] per-stop delay

  const Stop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
    this.expectedTime,
  });
}

/// prd.md Module 6 — Routes and Stops.
class TransportRoute {
  final String id;
  final String name; // e.g. "Route 7"
  final List<Stop> stops; // college → stop 1 → ... → stop N → college
  final double? estimatedDistanceKm;
  final Duration? expectedDuration;

  const TransportRoute({
    required this.id,
    required this.name,
    required this.stops,
    this.estimatedDistanceKm,
    this.expectedDuration,
  });
}

/// prd.md Module 4 — Bus (Fleet) Management, MVP fields only.
class Bus {
  final String id;
  final String busNumber;
  final String? registrationNumber;
  final int? capacity;

  const Bus({
    required this.id,
    required this.busNumber,
    this.registrationNumber,
    this.capacity,
  });
}

/// prd.md Module 5 — Driver Management, MVP fields only.
class DriverProfile {
  final String id;
  final String name;
  final String phone;

  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
  });
}

/// prd.md Module 9 — what the driver's phone reports while a trip is
/// active, and what students/managers see reflected back.
class LiveLocation {
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final double? headingDegrees;
  final DateTime updatedAt;

  const LiveLocation({
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    this.headingDegrees,
    required this.updatedAt,
  });

  /// flow.md Y4 — the watchdog rule for "Tracking unavailable".
  /// The exact threshold is a design.md §14 open question; 30s is a
  /// reasonable placeholder for the mock/demo layer.
  bool isStale({Duration threshold = const Duration(seconds: 30)}) =>
      DateTime.now().difference(updatedAt) > threshold;
}

/// prd.md Module 8 — Trips: one run of a bus on a route.
class Trip {
  final String id;
  final TransportRoute route;
  final Bus bus;
  final DriverProfile driver;
  final TripStage stage;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final LiveLocation? lastLocation;

  const Trip({
    required this.id,
    required this.route,
    required this.bus,
    required this.driver,
    required this.stage,
    this.startedAt,
    this.completedAt,
    this.lastLocation,
  });

  Trip copyWith({
    TripStage? stage,
    DateTime? startedAt,
    DateTime? completedAt,
    LiveLocation? lastLocation,
  }) {
    return Trip(
      id: id,
      route: route,
      bus: bus,
      driver: driver,
      stage: stage ?? this.stage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }
}

/// prd.md Module 12 — the eligibility chain:
/// enrolled? → fees valid? → route assigned? → bus assigned → access.
/// Kept as one type so S1 (flow.md) can switch on a single value
/// instead of four booleans.
enum EligibilityStatus {
  eligible,
  notEnrolled,
  feesPending,
  routeNotAssigned,
  cannotCheckRightNow, // ERP/backend unreachable — see flow.md Y6 branch
}
