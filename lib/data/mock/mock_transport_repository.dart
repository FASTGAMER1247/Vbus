import 'dart:async';
import 'dart:math';

import '../../core/models/transport_models.dart';
import '../repositories/transport_repository.dart';
import 'mock_seed.dart';

/// Fakes a bus moving along Route 7's stops so the live map (S2 in
/// flow.md) has something to render before real GPS data exists.
/// Swap this for data/remote/remote_transport_repository.dart once
/// the backend's Realtime channel is wired up — TransportRepository
/// is the contract both sides honor.
class MockTransportRepository implements TransportRepository {
  @override
  Future<EligibilityStatus> getMyEligibility(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // Change this to try the other S1 branches, e.g.
    // EligibilityStatus.feesPending, while building those states.
    return EligibilityStatus.eligible;
  }

  @override
  Future<TransportRoute?> getMyRoute(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.route7;
  }

  @override
  Future<Trip?> getMyActiveTrip(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.activeTrip();
  }

  @override
  Stream<LiveLocation> watchLiveLocation(String tripId) async* {
    final stops = MockSeed.stops;
    var segment = 0;
    var t = 0.0; // 0..1 progress along the current segment

    while (true) {
      await Future.delayed(const Duration(seconds: 2));

      final from = stops[segment % stops.length];
      final to = stops[(segment + 1) % stops.length];

      t += 0.12;
      if (t >= 1.0) {
        t = 0.0;
        segment++;
      }

      final lat = _lerp(from.latitude, to.latitude, t);
      final lng = _lerp(from.longitude, to.longitude, t);
      final heading = _bearing(from.latitude, from.longitude, to.latitude, to.longitude);

      yield LiveLocation(
        latitude: lat,
        longitude: lng,
        speedKmh: 22 + Random().nextInt(12).toDouble(),
        headingDegrees: heading,
        updatedAt: DateTime.now(),
      );
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _bearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * pi / 180;
    final y = sin(dLon) * cos(lat2 * pi / 180);
    final x = cos(lat1 * pi / 180) * sin(lat2 * pi / 180) -
        sin(lat1 * pi / 180) * cos(lat2 * pi / 180) * cos(dLon);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }
}
