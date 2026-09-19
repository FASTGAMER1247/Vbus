import 'dart:async';
import 'dart:math';

import '../../core/models/driver_models.dart';
import '../../core/models/transport_models.dart';
import '../../core/models/trip_stage.dart';
import '../repositories/driver_repository.dart';
import 'mock_seed.dart';

class MockDriverRepository implements DriverRepository {
  Trip? _currentTrip;

  @override
  Future<Trip?> getTodayScheduledTrip(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _currentTrip ?? MockSeed.todayScheduledTrip();
  }

  @override
  Future<Trip> identifyBus({required String driverId, required String busIdOrCode}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final outcome = MockSeed.demoBusOutcomes[busIdOrCode.trim()] ?? 'not_found';

    switch (outcome) {
      case 'ok':
        return MockSeed.todayScheduledTrip();
      case 'another_college':
        throw const DriverBlockedException(DriverBlockReason.busAnotherCollege);
      case 'not_assigned':
        throw const DriverBlockedException(DriverBlockReason.busNotAssignedToDriver);
      case 'already_active':
        throw const DriverBlockedException(DriverBlockReason.busAlreadyActive);
      case 'not_found':
      default:
        throw const DriverBlockedException(DriverBlockReason.busNotFound);
    }
  }

  @override
  Future<Trip> startTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentTrip = MockSeed.todayScheduledTrip().copyWith(
      stage: TripStage.onRoute,
      startedAt: DateTime.now(),
      lastLocation: LiveLocation(
        latitude: MockSeed.stops.first.latitude,
        longitude: MockSeed.stops.first.longitude,
        updatedAt: DateTime.now(),
      ),
    );
    return _currentTrip!;
  }

  @override
  Future<Trip> endTripManually(String tripId, {required bool insideGeofence}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final ended = (_currentTrip ?? MockSeed.todayScheduledTrip()).copyWith(
      stage: insideGeofence ? TripStage.completed : TripStage.endedManuallyByDriver,
      completedAt: DateTime.now(),
    );
    _currentTrip = null;
    return ended;
  }

  @override
  Stream<DriverDeviceHealth> watchDeviceHealth() async* {
    var battery = 78;
    var tick = 0;

    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      tick++;
      battery = max(5, battery - (tick % 4 == 0 ? 1 : 0)); // drains slowly

      // Every ~10th tick, briefly simulate a network/GPS wobble so D2's
      // warning banners and D3's offline path have something to show.
      final wobble = tick % 10 == 0;

      yield DriverDeviceHealth(
        gps: wobble ? GpsStatus.weak : GpsStatus.active,
        network: wobble ? NetworkStatus.offline : NetworkStatus.online,
        batteryPercent: battery,
        lastSyncAt: wobble ? DateTime.now().subtract(const Duration(seconds: 8)) : DateTime.now(),
      );
    }
  }
}
