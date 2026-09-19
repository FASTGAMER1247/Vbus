import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/driver_models.dart';
import '../../core/models/transport_models.dart';
import 'permissions_service.dart';

/// flow.md D1–D5 as one state machine. Screens read [driverFlowProvider]
/// and call methods on the notifier rather than talking to
/// DriverRepository directly — same "screens depend on the provider
/// layer, not the repository" pattern as student_providers.dart.
class DriverFlowState {
  final bool permissionsGranted;
  final Trip? scheduledTrip;
  final Trip? activeTrip;
  final DriverBlockReason? blockReason;
  final bool isLoading;

  const DriverFlowState({
    this.permissionsGranted = false,
    this.scheduledTrip,
    this.activeTrip,
    this.blockReason,
    this.isLoading = false,
  });

  DriverFlowState copyWith({
    bool? permissionsGranted,
    Trip? scheduledTrip,
    Trip? activeTrip,
    DriverBlockReason? blockReason,
    bool clearBlockReason = false,
    bool? isLoading,
  }) {
    return DriverFlowState(
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      scheduledTrip: scheduledTrip ?? this.scheduledTrip,
      activeTrip: activeTrip ?? this.activeTrip,
      blockReason: clearBlockReason ? null : (blockReason ?? this.blockReason),
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
    // driverId is hardcoded to the mock demo driver for now — will
    // come from authControllerProvider's user once every role has a
    // real id flowing through, same as student_providers.dart does.
    final trip = await repo.getTodayScheduledTrip('driver-1');
    state = state.copyWith(scheduledTrip: trip);
  }

  /// flow.md D1: "First trip: location permissions granted?"
  Future<bool> requestPermissions() async {
    state = state.copyWith(isLoading: true);
    final granted = await PermissionsService.requestLocationPermissions();
    state = state.copyWith(permissionsGranted: granted, isLoading: false);
    return granted;
  }

  /// D1 → identify the bus (QR or manual). Returns true on success;
  /// on failure, state.blockReason is set for D5.
  Future<bool> identifyBus(String busIdOrCode) async {
    state = state.copyWith(isLoading: true, clearBlockReason: true);
    try {
      final trip = await _ref.read(driverRepositoryProvider).identifyBus(
            driverId: 'driver-1',
            busIdOrCode: busIdOrCode,
          );
      state = state.copyWith(scheduledTrip: trip, isLoading: false);
      return true;
    } on DriverBlockedException catch (e) {
      state = state.copyWith(blockReason: e.reason, isLoading: false);
      return false;
    }
  }

  Future<void> startTrip() async {
    final scheduled = state.scheduledTrip;
    if (scheduled == null) return;
    state = state.copyWith(isLoading: true);
    final trip = await _ref.read(driverRepositoryProvider).startTrip(scheduled.id);
    state = state.copyWith(activeTrip: trip, isLoading: false);
  }

  /// flow.md D4 Path B — the driver's manual end button. The ended
  /// trip is also pushed into [lastCompletedTripProvider] so DR-9 can
  /// show a summary after state resets back to idle.
  Future<Trip> endTripManually({required bool insideGeofence}) async {
    final trip = state.activeTrip;
    state = state.copyWith(isLoading: true);
    final ended = await _ref.read(driverRepositoryProvider).endTripManually(
          trip!.id,
          insideGeofence: insideGeofence,
        );
    _ref.read(lastCompletedTripProvider.notifier).state = ended;
    state = const DriverFlowState(); // back to idle — D4 ends at "Driver home"
    return ended;
  }

  void clearBlock() => state = state.copyWith(clearBlockReason: true);
}

final driverFlowProvider = StateNotifierProvider<DriverFlowController, DriverFlowState>((ref) {
  return DriverFlowController(ref);
});

/// flow.md D2/D5 — streamed GPS/network/battery status.
final driverDeviceHealthProvider = StreamProvider<DriverDeviceHealth>((ref) {
  return ref.watch(driverRepositoryProvider).watchDeviceHealth();
});

/// Holds the just-ended trip so DR-9 (trip completed summary) has
/// something to show after driverFlowProvider resets to idle.
final lastCompletedTripProvider = StateProvider<Trip?>((ref) => null);
