import 'driver_models.dart';
import 'transport_models.dart';

/// Summary metrics for the manager dashboard (flow.md M2, prd.md Module 13).
class FleetSummary {
  final int activeBuses;
  final int inactiveBuses;
  final int activeTrips;
  final int completedTrips;
  final int offlineBuses;

  const FleetSummary({
    required this.activeBuses,
    required this.inactiveBuses,
    required this.activeTrips,
    required this.completedTrips,
    required this.offlineBuses,
  });

  int get totalBuses => activeBuses + inactiveBuses;
}

/// Driver <-> Bus <-> Route assignment (flow.md M1 Step 4, prd.md Module 7).
class FleetAssignment {
  final String id;
  final String collegeId;
  final String busId;
  final String driverId;
  final String routeId;
  final DateTime assignedAt;

  const FleetAssignment({
    required this.id,
    required this.collegeId,
    required this.busId,
    required this.driverId,
    required this.routeId,
    required this.assignedAt,
  });

  FleetAssignment copyWith({
    String? id,
    String? collegeId,
    String? busId,
    String? driverId,
    String? routeId,
    DateTime? assignedAt,
  }) {
    return FleetAssignment(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      busId: busId ?? this.busId,
      driverId: driverId ?? this.driverId,
      routeId: routeId ?? this.routeId,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }
}

/// Information displayed on the manager live fleet map for each bus (flow.md M2).
class FleetBusLocation {
  final Bus bus;
  final TransportRoute? route;
  final DriverProfile? driver;
  final Trip? activeTrip;
  final LiveLocation? location;
  final DriverDeviceHealth? health;

  const FleetBusLocation({
    required this.bus,
    this.route,
    this.driver,
    this.activeTrip,
    this.location,
    this.health,
  });

  bool get isTrackingActive => activeTrip != null && location != null && !location!.isStale();
  bool get isOffline => health?.network == NetworkStatus.offline || (location != null && location!.isStale());
}

/// Parameters to manually schedule a trip for today (flow.md M1 Step 5).
class CreateTripParams {
  final String collegeId;
  final String busId;
  final String driverId;
  final String routeId;
  final String shift; // e.g. "Morning", "Evening"

  const CreateTripParams({
    required this.collegeId,
    required this.busId,
    required this.driverId,
    required this.routeId,
    this.shift = 'Morning',
  });
}
