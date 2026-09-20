import '../../core/models/manager_models.dart';
import '../../core/models/transport_models.dart';

/// Abstract contract for Manager operations (flow.md M1–M5, prd.md Modules 4–7, 11, 13).
///
/// In Phase 3, this is implemented by [MockManagerRepository]. In Phase 6,
/// it will be implemented by [RemoteManagerRepository] backed by Supabase RPCs
/// (`get_fleet_status`, `generate_daily_trips`, `get_trip_summary`, etc.).
abstract class ManagerRepository {
  /// Dashboard metrics (M2).
  Future<FleetSummary> getFleetSummary(String collegeId);

  /// Bus fleet CRUD (M1 Step 1, prd.md Module 4).
  Future<List<Bus>> getBuses(String collegeId);
  Future<Bus> saveBus({required String collegeId, required Bus bus});
  Future<void> deleteBus(String busId);

  /// Driver profiles CRUD (M1 Step 2, prd.md Module 5).
  Future<List<DriverProfile>> getDrivers(String collegeId);
  Future<DriverProfile> saveDriver({required String collegeId, required DriverProfile driver});
  Future<void> deleteDriver(String driverId);

  /// Routes & stops CRUD (M1 Step 3, prd.md Module 6).
  Future<List<TransportRoute>> getRoutes(String collegeId);
  Future<TransportRoute> saveRoute({required String collegeId, required TransportRoute route});
  Future<void> deleteRoute(String routeId);

  /// Assignments: Driver <-> Bus <-> Route (M1 Step 4, prd.md Module 7).
  Future<List<FleetAssignment>> getAssignments(String collegeId);
  Future<FleetAssignment> saveAssignment(FleetAssignment assignment);
  Future<void> deleteAssignment(String assignmentId);

  /// Trip management & reports (M1 Step 5, M4, M5).
  Future<List<Trip>> getTrips(String collegeId);
  Future<Trip?> getTripById(String tripId);
  Future<Trip> createScheduledTrip(CreateTripParams params);
  Future<void> endStuckTrip({required String tripId, required String managerId});

  /// Live fleet monitoring stream (M2, M3).
  Stream<List<FleetBusLocation>> watchFleetLocations(String collegeId);
}
