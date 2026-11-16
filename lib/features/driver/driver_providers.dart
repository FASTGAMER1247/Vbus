import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/compliance_models.dart';
import '../../core/models/driver_models.dart';
import '../../core/models/transport_models.dart';
import 'driver_gps_service.dart';
import 'permissions_service.dart';

/// flow.md D1–D5 state machine with unassigned driver takeover and document compliance.
class DriverFlowState {
  final bool permissionsGranted;
  final Trip? scheduledTrip;
  final Trip? activeTrip;
  final DriverBlockReason? blockReason;
  final DocumentAlert? blockedDocumentAlert;
  final DocumentAlert? advisoryDocumentAlert;
  final bool isUnassignedTakeover;
  final bool isLoading;

  const DriverFlowState({
    this.permissionsGranted = false,
    this.scheduledTrip,
    this.activeTrip,
    this.blockReason,
    this.blockedDocumentAlert,
    this.advisoryDocumentAlert,
    this.isUnassignedTakeover = false,
    this.isLoading = false,
  });

  DriverFlowState copyWith({
    bool? permissionsGranted,
    Trip? scheduledTrip,
    Trip? activeTrip,
    DriverBlockReason? blockReason,
    DocumentAlert? blockedDocumentAlert,
    DocumentAlert? advisoryDocumentAlert,
    bool? isUnassignedTakeover,
    bool clearBlockReason = false,
    bool clearAdvisory = false,
    bool? isLoading,
  }) {
    return DriverFlowState(
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      scheduledTrip: scheduledTrip ?? this.scheduledTrip,
      activeTrip: activeTrip ?? this.activeTrip,
      blockReason: clearBlockReason ? null : (blockReason ?? this.blockReason),
      blockedDocumentAlert: clearBlockReason ? null : (blockedDocumentAlert ?? this.blockedDocumentAlert),
      advisoryDocumentAlert: clearAdvisory ? null : (advisoryDocumentAlert ?? this.advisoryDocumentAlert),
      isUnassignedTakeover: isUnassignedTakeover ?? this.isUnassignedTakeover,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DriverFlowController extends StateNotifier<DriverFlowState> {
  DriverFlowController(this._ref) : super(const DriverFlowState()) {
    _loadScheduledTrip();
  }

  final Ref _ref;

  Future<void> _loadScheduledTrip() async {
    final repo = _ref.read(driverRepositoryProvider);
    final user = _ref.read(authControllerProvider);
    final driverId = user?.id ?? 'driver-1';
    final trip = await repo.getTodayScheduledTrip(driverId);
    state = state.copyWith(scheduledTrip: trip);
  }

  /// flow.md D1: Location permissions check & request
  Future<bool> requestPermissions() async {
    state = state.copyWith(isLoading: true);
    final granted = await PermissionsService.requestLocationPermissions();
    state = state.copyWith(permissionsGranted: granted, isLoading: false);
    return granted;
  }

  /// D1 -> identify the bus (QR or manual ID).
  /// Returns [DriverScanResult] on success; on failure throws or sets blockReason.
  Future<DriverScanResult?> identifyBus(String busIdOrCode) async {
    state = state.copyWith(
      isLoading: true,
      clearBlockReason: true,
      clearAdvisory: true,
    );

    final user = _ref.read(authControllerProvider);
    final driverId = user?.id ?? 'driver-1';

    try {
      final result = await _ref.read(driverRepositoryProvider).identifyBus(
            driverId: driverId,
            busIdOrCode: busIdOrCode,
          );

      state = state.copyWith(
        scheduledTrip: result.trip,
        isUnassignedTakeover: result.isUnassignedTakeover,
        advisoryDocumentAlert: result.advisoryAlert,
        isLoading: false,
      );
      return result;
    } on DriverBlockedException catch (e) {
      state = state.copyWith(
        blockReason: e.reason,
        blockedDocumentAlert: e.documentAlert,
        isLoading: false,
      );
      return null;
    }
  }

  Future<void> startTrip() async {
    final scheduled = state.scheduledTrip;
    if (scheduled == null) return;
    state = state.copyWith(isLoading: true);
    final trip = await _ref.read(driverRepositoryProvider).startTrip(scheduled.id);
    state = state.copyWith(activeTrip: trip, isLoading: false);
    _ref.read(driverGpsTrackingProvider.notifier).startTracking(trip: trip);
  }

  /// flow.md D4 Path B - driver's manual end trip.
  Future<Trip> endTripManually({required bool insideGeofence}) async {
    final trip = state.activeTrip;
    state = state.copyWith(isLoading: true);
    _ref.read(driverGpsTrackingProvider.notifier).stopTracking();
    final ended = await _ref.read(driverRepositoryProvider).endTripManually(
          trip?.id ?? '',
          insideGeofence: insideGeofence,
        );
    state = state.copyWith(activeTrip: null, isLoading: false);
    _ref.read(lastCompletedTripProvider.notifier).state = ended;
    return ended;
  }
}

final driverFlowProvider =
    StateNotifierProvider<DriverFlowController, DriverFlowState>((ref) {
  return DriverFlowController(ref);
});

final driverDeviceHealthProvider = StreamProvider<DriverDeviceHealth>((ref) {
  return ref.watch(driverRepositoryProvider).watchDeviceHealth();
});

final driverLiveLocationProvider = StreamProvider<LiveLocation>((ref) {
  return ref.watch(driverRepositoryProvider).watchDriverLocation();
});

/// Real-time route progress & upcoming stop calculations for the driver.
final driverRouteProgressProvider = Provider<RouteProgress?>((ref) {
  final trip = ref.watch(driverFlowProvider).activeTrip;
  if (trip == null || trip.route.stops.isEmpty) return null;
  final locAsync = ref.watch(driverLiveLocationProvider);
  final loc = locAsync.value ?? trip.lastLocation;

  final lat = loc?.latitude ?? trip.route.stops.first.latitude;
  final lng = loc?.longitude ?? trip.route.stops.first.longitude;

  return trip.route.calculateProgress(
    busLat: lat,
    busLng: lng,
    speedKmh: loc?.speedKmh,
  );
});

final lastCompletedTripProvider = StateProvider<Trip?>((ref) => null);
