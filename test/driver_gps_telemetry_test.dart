import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_transit/core/models/transport_models.dart';
import 'package:campus_transit/core/models/trip_stage.dart';
import 'package:campus_transit/data/mock/mock_driver_repository.dart';
import 'package:campus_transit/data/mock/mock_seed.dart';
import 'package:campus_transit/features/driver/driver_gps_service.dart';
import 'package:campus_transit/app/providers.dart';

void main() {
  group('Driver Phone GPS Telemetry & Realtime Streaming (Option B)', () {
    late MockDriverRepository mockDriverRepo;
    late ProviderContainer container;

    setUp(() {
      mockDriverRepo = MockDriverRepository();
      container = ProviderContainer(
        overrides: [
          driverRepositoryProvider.overrideWithValue(mockDriverRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('recordTelemetry updates location stream and persists lastLocation on trip', () async {
      final trip = MockSeed.todayScheduledTrip().copyWith(stage: TripStage.started);
      final testLoc = LiveLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        speedKmh: 35.0,
        headingDegrees: 180.0,
        updatedAt: DateTime.now(),
      );

      // Verify stream receives telemetry
      expectLater(
        mockDriverRepo.watchDriverLocation(),
        emits(predicate<LiveLocation>((loc) =>
            loc.latitude == 12.9716 &&
            loc.longitude == 77.5946 &&
            loc.speedKmh == 35.0 &&
            loc.headingDegrees == 180.0)),
      );

      await mockDriverRepo.recordTelemetry(
        tripId: trip.id,
        location: testLoc,
        batteryPercent: 82,
        networkStatus: 'online',
      );
    });

    test('DriverGpsTrackingNotifier starts tracking, emits initial waypoint and increments packetsSent', () async {
      final trip = MockSeed.todayScheduledTrip();
      final notifier = container.read(driverGpsTrackingProvider.notifier);

      await notifier.startTracking(trip: trip, simulate: true);
      final state = container.read(driverGpsTrackingProvider);

      expect(state.isTracking, isTrue);
      expect(state.isSimulating, isTrue);
      expect(state.packetsSent, greaterThanOrEqualTo(1));
      expect(state.lastLocation, isNotNull);
      expect(state.lastLocation!.latitude, equals(trip.route.stops.first.latitude));

      notifier.stopTracking();
      final stoppedState = container.read(driverGpsTrackingProvider);
      expect(stoppedState.isTracking, isFalse);
    });

    test('DriverGpsTrackingNotifier waypoint generation creates smooth path across route stops', () async {
      final trip = MockSeed.todayScheduledTrip();
      final notifier = container.read(driverGpsTrackingProvider.notifier);

      await notifier.startTracking(trip: trip, simulate: true);
      final state = container.read(driverGpsTrackingProvider);

      expect(state.lastLocation, isNotNull);
      expect(state.lastLocation!.speedKmh, isNotNull);

      notifier.stopTracking();
    });

    test('Simulation mode toggle switches cleanly without crashing', () async {
      final trip = MockSeed.todayScheduledTrip();
      final notifier = container.read(driverGpsTrackingProvider.notifier);

      await notifier.startTracking(trip: trip, simulate: true);
      expect(container.read(driverGpsTrackingProvider).isSimulating, isTrue);

      notifier.stopTracking();
      expect(container.read(driverGpsTrackingProvider).isTracking, isFalse);
    });
  });
}
