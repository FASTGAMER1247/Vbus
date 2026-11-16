import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/compliance_models.dart';
import '../../core/models/erp_models.dart';
import '../../core/models/manager_models.dart';
import '../../core/models/transport_models.dart';

/// Metric summary for the dashboard cards (flow.md M2).
final fleetSummaryProvider = FutureProvider.autoDispose<FleetSummary>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getFleetSummary(collegeId);
});

/// List of all buses belonging to the manager's college (M1 Step 1).
final busesProvider = FutureProvider.autoDispose<List<Bus>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getBuses(collegeId);
});

/// List of all drivers belonging to the manager's college (M1 Step 2).
final driversProvider = FutureProvider.autoDispose<List<DriverProfile>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getDrivers(collegeId);
});

/// List of all routes belonging to the manager's college (M1 Step 3).
final routesProvider = FutureProvider.autoDispose<List<TransportRoute>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getRoutes(collegeId);
});

/// List of active Driver <-> Bus <-> Route assignments (M1 Step 4).
final assignmentsProvider = FutureProvider.autoDispose<List<FleetAssignment>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getAssignments(collegeId);
});

/// List of all trips (scheduled, active, completed) (M1 Step 5, M4).
final tripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getTrips(collegeId);
});

/// Single trip lookup for summary review and resolution (M4, M5).
final tripDetailProvider = FutureProvider.family.autoDispose<Trip?, String>((ref, tripId) {
  return ref.watch(managerRepositoryProvider).getTripById(tripId);
});

/// Real-time live fleet stream powering the manager fleet map (M2, M3).
final liveFleetLocationsProvider = StreamProvider.autoDispose<List<FleetBusLocation>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).watchFleetLocations(collegeId);
});

/// Document compliance and expiry alerts (BUS_APP Phase 25).
final complianceAlertsProvider = FutureProvider.autoDispose<List<DocumentAlert>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getComplianceAlerts(collegeId);
});

/// List of enrolled students synced from College ERP (vmax / CampX) (BUS_APP Phase 21).
final enrolledStudentsProvider = FutureProvider.autoDispose<List<ErpStudent>>((ref) {
  final user = ref.watch(authControllerProvider);
  final collegeId = user?.collegeId ?? 'college-vjit';
  return ref.watch(managerRepositoryProvider).getEnrolledStudents(collegeId);
});

/// Latest ERP batch sync results and summary metrics.
final lastErpSyncResultProvider = StateProvider<ErpSyncResult?>((ref) => null);

/// Controller for triggering on-demand sync from College ERP (vmax) and updating fee status.
final erpSyncControllerProvider = StateNotifierProvider<ErpSyncNotifier, AsyncValue<ErpSyncResult?>>((ref) {
  return ErpSyncNotifier(ref);
});

class ErpSyncNotifier extends StateNotifier<AsyncValue<ErpSyncResult?>> {
  final Ref _ref;

  ErpSyncNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<ErpSyncResult?> triggerSync({List<ErpStudent>? manualStudents}) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authControllerProvider);
      final collegeId = user?.collegeId ?? 'college-vjit';
      final repo = _ref.read(managerRepositoryProvider);
      final result = await repo.syncFromCollegeErp(
        collegeId: collegeId,
        manualStudents: manualStudents,
      );
      _ref.read(lastErpSyncResultProvider.notifier).state = result;
      _ref.invalidate(enrolledStudentsProvider);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateFeeStatus({
    required String rollNumber,
    required ErpFeeStatus status,
  }) async {
    final user = _ref.read(authControllerProvider);
    final collegeId = user?.collegeId ?? 'college-vjit';
    final repo = _ref.read(managerRepositoryProvider);
    await repo.updateStudentFeeStatus(
      collegeId: collegeId,
      rollNumber: rollNumber,
      status: status,
    );
    _ref.invalidate(enrolledStudentsProvider);
  }
}
