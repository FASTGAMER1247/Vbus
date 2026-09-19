/// prd.md §9.1 / design.md §9.1 — the three health indicators shown
/// to the driver during a trip, and to the manager per bus.
enum GpsStatus { active, weak, unavailable }

enum NetworkStatus { online, weak, offline }

class DriverDeviceHealth {
  final GpsStatus gps;
  final NetworkStatus network;
  final int batteryPercent;
  final DateTime lastSyncAt;

  const DriverDeviceHealth({
    required this.gps,
    required this.network,
    required this.batteryPercent,
    required this.lastSyncAt,
  });

  bool get isBatteryLow => batteryPercent <= 20 && batteryPercent > 10;
  bool get isBatteryCritical => batteryPercent <= 10;
}

/// flow.md D5 / design.md §5.3 DR-10 — every reason a trip can't start,
/// and the exact copy to show (prd.md §12 tone: never accusatory).
enum DriverBlockReason {
  busNotFound,
  busAnotherCollege,
  busNotAssignedToDriver,
  busAlreadyActive,
  locationPermissionDenied;

  String get message {
    switch (this) {
      case DriverBlockReason.busNotFound:
        return 'This bus could not be found. Check the code or Bus ID.';
      case DriverBlockReason.busAnotherCollege:
        return 'This bus is not available.';
      case DriverBlockReason.busNotAssignedToDriver:
        return 'This bus is not assigned to you. Contact your manager.';
      case DriverBlockReason.busAlreadyActive:
        return 'This bus already has a trip in progress.';
      case DriverBlockReason.locationPermissionDenied:
        return 'Location access is needed to start a trip.';
    }
  }
}

class DriverBlockedException implements Exception {
  final DriverBlockReason reason;
  const DriverBlockedException(this.reason);
}
