import '../../core/models/driver_models.dart';
import '../../core/models/transport_models.dart';

/// Driver-facing operations (flow.md D1–D5). Kept separate from
/// TransportRepository (the student/faculty read side) because the
/// backend's actual RPCs are split the same way — start_trip,
/// complete_trip etc. are driver/admin-only, with different allowed
/// roles than the student read RPCs. See BACKEND_CHANGES.md #6 for
/// the identifyBus gap this interface is written around.
abstract class DriverRepository {
  /// flow.md D1 "before": a trip must already exist as scheduled.
  /// Null if nothing is scheduled for this driver today.
  Future<Trip?> getTodayScheduledTrip(String driverId);

  /// Resolves a scanned QR code or manually-entered Bus ID to that
  /// scheduled trip, or throws [DriverBlockedException] with the exact
  /// reason (flow.md D5). Backend note: there's no bus-lookup RPC
  /// today — start_trip only takes a trip ID — so the mock
  /// implementation does this resolution client-side. Once the
  /// backend adds start_trip_by_bus(code), this method's real
  /// implementation just calls that.
  Future<Trip> identifyBus({required String driverId, required String busIdOrCode});

  Future<Trip> startTrip(String tripId);

  /// flow.md D4 Path B. [insideGeofence] decides the wording shown
  /// ("trip completes normally" vs "ended manually outside the college").
  Future<Trip> endTripManually(String tripId, {required bool insideGeofence});

  /// flow.md D2/D5 — GPS, network, battery, last sync. Streamed so the
  /// active-trip screen can react to changes (low battery, GPS loss).
  Stream<DriverDeviceHealth> watchDeviceHealth();
}
