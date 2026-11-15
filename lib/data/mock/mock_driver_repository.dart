import 'dart:async';
import 'dart:math';

import '../../core/models/driver_models.dart';
import '../../core/models/transport_models.dart';
import '../../core/models/trip_stage.dart';
import '../repositories/driver_repository.dart';
import 'mock_seed.dart';

class MockDriverRepository implements DriverRepository {
  Trip? _currentTrip;
  final StreamController<LiveLocation> _locationController =
      StreamController<LiveLocation>.broadcast();

  @override
  Future<Trip?> getTodayScheduledTrip(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _currentTrip ?? MockSeed.todayScheduledTrip();
  }

  @override
  Future<DriverScanResult> identifyBus({
    required String driverId,
    required String busIdOrCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final cleanCode = busIdOrCode.trim();

    // 1. Driver License Compliance check
    if (driverId == 'driver-2') {
      final licenseAlert = MockSeed.initialComplianceAlerts.firstWhere(
        (a) => a.id == 'alert-3',
      );
      throw DriverBlockedException(
        DriverBlockReason.driverLicenseExpired,
        documentAlert: licenseAlert,
      );
    }

    // 2. Resolve bus outcome
    final outcome = MockSeed.demoBusOutcomes[cleanCode] ??
        (cleanCode.contains('023')
            ? 'ok'
            : cleanCode.contains('015')
                ? 'unassigned_takeover'
                : cleanCode.contains('009')
                    ? 'puc_expiring_soon'
                    : cleanCode.contains('042')
                        ? 'insurance_expired'
                        : 'not_found');

    switch (outcome) {
      case 'ok':
        return DriverScanResult(
          trip: MockSeed.todayScheduledTrip(),
          isUnassignedTakeover: false,
        );

      case 'unassigned_takeover':
        // User Addition: Driver with no prior assignment can take over an available bus!
        final takeoverTrip = MockSeed.scheduledTripForBus(MockSeed.bus015);
        return DriverScanResult(
          trip: takeoverTrip,
          isUnassignedTakeover: true,
        );

      case 'puc_expiring_soon':
        // User Addition: Advisory alert for expiring document (e.g. PUC in 5 days)
        final pucAlert = MockSeed.initialComplianceAlerts.firstWhere(
          (a) => a.id == 'alert-2',
        );
        return DriverScanResult(
          trip: MockSeed.scheduledTripForBus(MockSeed.bus009),
          isUnassignedTakeover: false,
          advisoryAlert: pucAlert,
        );

      case 'insurance_expired':
        // User Addition: Block trip if bus document expired (e.g. Insurance)
        final insuranceAlert = MockSeed.initialComplianceAlerts.firstWhere(
          (a) => a.id == 'alert-1',
        );
        throw DriverBlockedException(
          DriverBlockReason.busDocumentExpired,
          documentAlert: insuranceAlert,
        );

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
        speedKmh: 24,
        headingDegrees: 45,
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
    var battery = 82;
    var tick = 0;

    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      tick++;
      battery = max(5, battery - (tick % 5 == 0 ? 1 : 0));

      final wobble = tick % 12 == 0;
      final speed = (25 + (tick % 7) * 3).toDouble();
      final heading = ((tick * 15) % 360).toDouble();

      // Simulate vehicle moving along coordinates towards campus
      final lat = MockSeed.stops[tick % MockSeed.stops.length].latitude;
      final lng = MockSeed.stops[tick % MockSeed.stops.length].longitude;

      final distance = _calculateHaversineDistance(
        lat,
        lng,
        MockSeed.campusLatitude,
        MockSeed.campusLongitude,
      );

      _locationController.add(LiveLocation(
        latitude: lat,
        longitude: lng,
        speedKmh: speed,
        headingDegrees: heading,
        updatedAt: DateTime.now(),
      ));

      yield DriverDeviceHealth(
        gps: wobble ? GpsStatus.weak : GpsStatus.active,
        network: wobble ? NetworkStatus.offline : NetworkStatus.online,
        batteryPercent: battery,
        lastSyncAt: wobble ? DateTime.now().subtract(const Duration(seconds: 8)) : DateTime.now(),
        currentSpeedKmh: speed,
        currentHeading: heading,
        distanceToCampusMeters: distance,
      );
    }
  }

  @override
  Stream<LiveLocation> watchDriverLocation() => _locationController.stream;

  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}
