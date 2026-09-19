import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_typography.dart';
import '../../core/widgets/freshness_label.dart';
import 'student_providers.dart';

/// flow.md S2 — Track my bus live. Screen ST-5. Layout follows
/// design.md §11.2: map, ETA card overlaid at the bottom, freshness
/// label always visible (design.md §8.2 rule).
///
/// Backend note: once real GPS lands, only liveLocationProvider's
/// source changes (data/remote/remote_transport_repository.dart) —
/// this screen doesn't change at all.
class StudentLiveMapScreen extends ConsumerWidget {
  const StudentLiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(myActiveTripProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live')),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Something went wrong.')),
        data: (trip) {
          if (trip == null) {
            // flow.md S4: bus hasn't started
            return const Center(child: Text('Your bus has not started yet.'));
          }
          return _LiveMap(tripId: trip.id, stops: trip.route.stops.map((s) => LatLng(s.latitude, s.longitude)).toList());
        },
      ),
    );
  }
}

class _LiveMap extends ConsumerWidget {
  final String tripId;
  final List<LatLng> stops;

  const _LiveMap({required this.tripId, required this.stops});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(liveLocationProvider(tripId));

    return locationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Tracking unavailable.')),
      data: (location) {
        final busPoint = LatLng(location.latitude, location.longitude);
        final myStop = stops.last;

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(initialCenter: busPoint, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.campus_transit',
                ),
                PolylineLayer(polylines: [
                  Polyline(points: stops, strokeWidth: 3, color: Colors.blueGrey),
                ]),
                MarkerLayer(markers: [
                  ...stops.map((p) => Marker(
                        point: p,
                        width: 14,
                        height: 14,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      )),
                  Marker(
                    point: myStop,
                    width: 28,
                    height: 28,
                    child: const Icon(Icons.flag, color: Colors.deepOrange),
                  ),
                  Marker(
                    point: busPoint,
                    width: 36,
                    height: 36,
                    child: Transform.rotate(
                      angle: ((location.headingDegrees ?? 0) * 3.14159 / 180),
                      child: const Icon(Icons.directions_bus, color: Colors.blue, size: 32),
                    ),
                  ),
                ]),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Arriving at ${_stopName(myStop)}', style: AppTypography.heading),
                            const SizedBox(height: 4),
                            // Real ETA needs route-progress data the backend already
                            // computes (get_student_route_eta) — placeholder for now.
                            const Text('~12 min', style: AppTypography.display),
                          ],
                        ),
                      ),
                      FreshnessLabel(updatedAt: location.updatedAt),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _stopName(LatLng p) => 'your stop'; // stop objects aren't threaded through here yet — fine for the mock
}
