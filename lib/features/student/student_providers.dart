import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/transport_models.dart';

/// flow.md S1's eligibility check.
final myEligibilityProvider = FutureProvider<EligibilityStatus>((ref) async {
  final user = ref.watch(authControllerProvider);
  if (user == null) return EligibilityStatus.cannotCheckRightNow;
  return ref.watch(transportRepositoryProvider).getMyEligibility(user.id);
});

final myRouteProvider = FutureProvider<TransportRoute?>((ref) async {
  final user = ref.watch(authControllerProvider);
  if (user == null) return null;
  return ref.watch(transportRepositoryProvider).getMyRoute(user.id);
});

final myActiveTripProvider = FutureProvider<Trip?>((ref) async {
  final user = ref.watch(authControllerProvider);
  if (user == null) return null;
  return ref.watch(transportRepositoryProvider).getMyActiveTrip(user.id);
});

/// flow.md S2: live position updates while a trip is in progress.
final liveLocationProvider = StreamProvider.family<LiveLocation, String>((ref, tripId) {
  return ref.watch(transportRepositoryProvider).watchLiveLocation(tripId);
});

/// Stop-by-stop route progression and real-time ETAs computed on every GPS tick.
final routeProgressProvider = Provider.family<RouteProgress?, String>((ref, tripId) {
  final locationAsync = ref.watch(liveLocationProvider(tripId));
  final routeAsync = ref.watch(myRouteProvider);

  final location = locationAsync.value;
  final route = routeAsync.value;

  if (location == null || route == null || route.stops.isEmpty) {
    return null;
  }

  return route.calculateProgress(
    busLat: location.latitude,
    busLng: location.longitude,
    speedKmh: location.speedKmh,
    userStopId: 'stop-4', // In demo, student's assigned stop is Bharat Nagar
  );
});
