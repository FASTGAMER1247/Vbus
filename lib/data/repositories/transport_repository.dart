import '../../core/models/transport_models.dart';

/// Student/faculty-facing read operations (flow.md S1–S4). A screen
/// asks for getMyEligibility() / getMyRoute() / watchActiveTrip() and
/// never cares whether the answer came from mock data or a real RPC.
///
/// Backend note: today this would read from the backend's own
/// `student_bus_fees` table, not a real ERP — see BACKEND_CHANGES.md
/// item #1 and prd.md §15.4. The interface doesn't change either way.
abstract class TransportRepository {
  Future<EligibilityStatus> getMyEligibility(String userId);

  /// Null if the person has no route assigned yet (flow.md S1 branch:
  /// "Route not assigned yet").
  Future<TransportRoute?> getMyRoute(String userId);

  /// Null if the assigned bus hasn't started a trip today (flow.md S4).
  Future<Trip?> getMyActiveTrip(String userId);

  /// Live position updates for a trip already in progress. The mock
  /// implementation fakes movement along the route so the map screen
  /// has something to show before real GPS data exists.
  Stream<LiveLocation> watchLiveLocation(String tripId);
}
