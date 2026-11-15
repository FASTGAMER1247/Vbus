import 'package:flutter_test/flutter_test.dart';
import 'package:campus_transit/core/models/transport_models.dart';

void main() {
  group('Route Progress & Dynamic ETAs (Option 1)', () {
    const stop1 = Stop(
      id: 'stop-1',
      name: 'Central Metro Station',
      latitude: 12.9716,
      longitude: 77.5946,
      order: 1,
      expectedTime: '7:30 AM',
    );
    const stop2 = Stop(
      id: 'stop-2',
      name: 'Tech Park Gate 2',
      latitude: 12.9800,
      longitude: 77.6000,
      order: 2,
      expectedTime: '7:42 AM',
    );
    const stop3 = Stop(
      id: 'stop-3',
      name: 'Greenwood Junction',
      latitude: 12.9900,
      longitude: 77.6100,
      order: 3,
      expectedTime: '7:55 AM',
    );
    const stop4 = Stop(
      id: 'stop-4',
      name: 'College Main Campus',
      latitude: 13.0000,
      longitude: 77.6200,
      order: 4,
      expectedTime: '8:10 AM',
    );

    const testRoute = TransportRoute(
      id: 'route-test',
      name: 'Campus Express Route 9',
      stops: [stop1, stop2, stop3, stop4],
      estimatedDistanceKm: 12.5,
    );

    test('Bus dwelling at Stop 1 identifies as atStop with 1 min ETA', () {
      final progress = testRoute.calculateProgress(
        busLat: 12.971605, // within ~5 meters of Stop 1
        busLng: 77.594605,
        speedKmh: 0,
        userStopId: 'stop-3',
      );

      expect(progress.completedStopsCount, equals(0));
      expect(progress.totalStopsCount, equals(4));
      expect(progress.nextStop.id, equals('stop-1'));

      final s1Prog = progress.allStops.firstWhere((s) => s.stop.id == 'stop-1');
      expect(s1Prog.stage, equals(StopStage.atStop));
      expect(s1Prog.estimatedMinutes, equals(1));

      // Stop 2, 3, 4 should be upcoming with progressive ETAs
      final s2Prog = progress.allStops.firstWhere((s) => s.stop.id == 'stop-2');
      final s3Prog = progress.allStops.firstWhere((s) => s.stop.id == 'stop-3');
      final s4Prog = progress.allStops.firstWhere((s) => s.stop.id == 'stop-4');

      expect(s2Prog.stage, equals(StopStage.upcoming));
      expect(s3Prog.stage, equals(StopStage.upcoming));
      expect(s4Prog.stage, equals(StopStage.upcoming));

      expect(s2Prog.estimatedMinutes, greaterThan(s1Prog.estimatedMinutes));
      expect(s3Prog.estimatedMinutes, greaterThan(s2Prog.estimatedMinutes));
      expect(s4Prog.estimatedMinutes, greaterThan(s3Prog.estimatedMinutes));
    });

    test('Bus between Stop 1 and Stop 2 identifies Stop 2 as next', () {
      // Approximate midpoint between stop 1 and stop 2
      final progress = testRoute.calculateProgress(
        busLat: 12.9790,
        busLng: 77.5990,
        speedKmh: 30.0,
        userStopId: 'stop-2',
      );

      expect(progress.nextStop.id, equals('stop-2'));
      expect(progress.minutesToNextStop, greaterThanOrEqualTo(1));
      expect(progress.distanceToNextStopMeters, lessThan(300));

      expect(progress.isUserStopNext, isTrue);
      expect(progress.userEtaMinutes, equals(progress.minutesToNextStop));
    });

    test('Bus past Stop 2 marks earlier stops as passed', () {
      // Near Stop 3
      final progress = testRoute.calculateProgress(
        busLat: 12.9901,
        busLng: 77.6101,
        speedKmh: 20.0,
        userStopId: 'stop-4',
      );

      final s1Prog = progress.allStops.firstWhere((s) => s.stop.id == 'stop-1');
      final s2Prog = progress.allStops.firstWhere((s) => s.stop.id == 'stop-2');
      final s3Prog = progress.allStops.firstWhere((s) => s.stop.id == 'stop-3');

      expect(s1Prog.stage, equals(StopStage.passed));
      expect(s2Prog.stage, equals(StopStage.passed));
      expect(s3Prog.stage, isIn([StopStage.atStop, StopStage.next]));
    });

    test('User stop progress and dynamic countdown correctly tracked', () {
      final progress = testRoute.calculateProgress(
        busLat: 12.9716,
        busLng: 77.5946,
        userStopId: 'stop-3',
      );

      expect(progress.userStopProgress, isNotNull);
      expect(progress.userStopProgress!.stop.id, equals('stop-3'));
      expect(progress.userStopProgress!.isUserStop, isTrue);
      expect(progress.userEtaMinutes, greaterThan(0));
    });
  });
}
