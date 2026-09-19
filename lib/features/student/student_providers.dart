import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/transport_models.dart';

/// flow.md S1's three checks, and the data ST-5/S2 needs. Each is a
/// thin FutureProvider over TransportRepository — screens watch these,
/// never the repository directly, so a screen only re-fetches when its
/// own data actually changes.
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
