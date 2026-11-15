import 'compliance_models.dart';
import 'transport_models.dart';

/// prd.md §9.1 / design.md §9.1 — the three health indicators shown
/// to the driver during a trip, and to the manager per bus.
enum GpsStatus { active, weak, unavailable }

enum NetworkStatus { online, weak, offline }

class DriverDeviceHealth {
  final GpsStatus gps;
  final NetworkStatus network;
  final int batteryPercent;
  final DateTime lastSyncAt;
  final double? currentSpeedKmh;
  final double? currentHeading;
  final double? distanceToCampusMeters;

  const DriverDeviceHealth({
    required this.gps,
    required this.network,
    required this.batteryPercent,
    required this.lastSyncAt,
    this.currentSpeedKmh,
    this.currentHeading,
    this.distanceToCampusMeters,
  });

  bool get isBatteryLow => batteryPercent <= 20 && batteryPercent > 10;
  bool get isBatteryCritical => batteryPercent <= 10;
}

/// flow.md D5 / design.md §5.3 DR-10 — every reason a trip can't start,
/// including document & license compliance blocks.
enum DriverBlockReason {
  busNotFound,
  busAnotherCollege,
  busNotAssignedToDriver,
  busAlreadyActive,
  locationPermissionDenied,
  driverLicenseExpired,
  busDocumentExpired;

  String get message {
    switch (this) {
      case DriverBlockReason.busNotFound:
        return 'This bus could not be found. Check the code or Bus ID.';
      case DriverBlockReason.busAnotherCollege:
        return 'This bus belongs to another institution and is not available.';
      case DriverBlockReason.busNotAssignedToDriver:
        return 'This bus is assigned to another driver. Contact your transport manager.';
      case DriverBlockReason.busAlreadyActive:
        return 'This bus already has a live trip in progress.';
      case DriverBlockReason.locationPermissionDenied:
        return 'Location access is needed to start a trip.';
      case DriverBlockReason.driverLicenseExpired:
        return 'Your commercial driving license has expired. Contact your manager immediately.';
      case DriverBlockReason.busDocumentExpired:
        return 'This bus has expired legal documents (RC/PUC/Insurance) and cannot be operated.';
    }
  }
}

class DriverBlockedException implements Exception {
  final DriverBlockReason reason;
  final DocumentAlert? documentAlert;

  const DriverBlockedException(this.reason, {this.documentAlert});

  @override
  String toString() => 'DriverBlockedException($reason, alert: ${documentAlert?.documentType})';
}

/// Result of identifying a bus via QR or ID scan.
class DriverScanResult {
  final Trip trip;
  final bool isUnassignedTakeover; // true if driver had no prior assignment but was authorized
  final DocumentAlert? advisoryAlert; // non-blocking (e.g. expiring in 6 days)

  const DriverScanResult({
    required this.trip,
    this.isUnassignedTakeover = false,
    this.advisoryAlert,
  });
}
