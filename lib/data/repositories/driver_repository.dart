import '../../core/models/driver_models.dart';
import '../../core/models/transport_models.dart';

/// Driver-facing operations (flow.md D1–D5).
abstract class DriverRepository {
  /// flow.md D1 "before": a trip must already exist as scheduled.
  /// Null if nothing is scheduled for this driver today.
  Future<Trip?> getTodayScheduledTrip(String driverId);

  /// Resolves a scanned QR code or manually-entered Bus ID to that
  /// scheduled trip, or allows an unassigned driver to take over an available bus.
  /// Throws [DriverBlockedException] with the exact reason if blocked (expired doc, mismatch, etc.).
  Future<DriverScanResult> identifyBus({
    required String driverId,
    required String busIdOrCode,
  });

  /// Starts the trip and begins active tracking.
  Future<Trip> startTrip(String tripId);

  /// flow.md D4 Path B: ends the trip manually.
  Future<Trip> endTripManually(String tripId, {required bool insideGeofence});

  /// Broadcasts the driver's phone telemetry (GPS, battery, network, distance to campus).
  Stream<DriverDeviceHealth> watchDeviceHealth();

  /// Stream of the driver's live GPS coordinates.
  Stream<LiveLocation> watchDriverLocation();
}
