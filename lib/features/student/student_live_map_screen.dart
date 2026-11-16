import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/transport_models.dart';
import '../../core/widgets/freshness_label.dart';
import 'student_providers.dart';

/// flow.md S2 — Track my bus live (Screen ST-5).
/// Overlaid ETA card with real-time dynamic stop progress and arrival countdown.
class StudentLiveMapScreen extends ConsumerWidget {
  const StudentLiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(myActiveTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        backgroundColor: AppColors.studentAccent,
      ),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Something went wrong.')),
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Your bus has not started yet.'));
          }
          return _LiveMap(
            tripId: trip.id,
            route: trip.route,
          );
        },
      ),
    );
  }
}

class _LiveMap extends ConsumerWidget {
  final String tripId;
  final TransportRoute route;

  const _LiveMap({required this.tripId, required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(liveLocationProvider(tripId));
    final progress = ref.watch(routeProgressProvider(tripId));
    final stops = route.stops.map((s) => LatLng(s.latitude, s.longitude)).toList();

    return locationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Tracking unavailable.')),
      data: (location) {
        final busPoint = LatLng(location.latitude, location.longitude);
        final userStopProgress = progress?.userStopProgress;
        final userStop = userStopProgress?.stop ?? route.stops.last;

        final etaMinutes = progress?.userEtaMinutes ?? 8;
        final isAtStop = progress?.isUserStopAtStop ?? false;

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
                  Polyline(points: stops, strokeWidth: 4, color: AppColors.studentAccent.withValues(alpha: 0.6)),
                ]),
                MarkerLayer(markers: [
                  // Stops along route
                  ...route.stops.map((s) {
                    final isUserStop = s.id == userStop.id;
                    final stopProg = progress?.allStops.where((p) => p.stop.id == s.id).firstOrNull;
                    final isPassed = stopProg?.stage == StopStage.passed;
                    final isNext = stopProg?.stage == StopStage.next || stopProg?.stage == StopStage.atStop;

                    if (isUserStop) {
                      return Marker(
                        point: LatLng(s.latitude, s.longitude),
                        width: 38,
                        height: 38,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.deepOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return Marker(
                      point: LatLng(s.latitude, s.longitude),
                      width: 18,
                      height: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isPassed
                              ? Colors.grey.shade400
                              : (isNext ? AppColors.studentAccent : Colors.blueGrey),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    );
                  }),

                  // Moving Bus Marker with heading rotation
                  Marker(
                    point: busPoint,
                    width: 44,
                    height: 44,
                    child: Transform.rotate(
                      angle: ((location.headingDegrees ?? 0) * 3.14159 / 180),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.directions_bus, color: AppColors.studentAccent, size: 28),
                      ),
                    ),
                  ),
                ]),
              ],
            ),

            // Live Realtime Telemetry floating pill at top
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.statusGood,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live GPS Telemetry · ${location.speedKmh?.toInt() ?? 0} km/h',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        route.name,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dynamic Live ETA Card overlaid at bottom
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.statusGood,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAtStop ? 'BUS ARRIVING NOW' : 'EN ROUTE TO YOUR STOP',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppColors.studentAccent,
                                ),
                              ),
                            ],
                          ),
                          FreshnessLabel(updatedAt: location.updatedAt),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userStop.name,
                                  style: AppTypography.heading.copyWith(fontSize: 20),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                if (progress?.nextStop != null && progress!.nextStop.id != userStop.id)
                                  Text(
                                    'Approaching next: ${progress.nextStop.name} (~${progress.minutesToNextStop} min)',
                                    style: AppTypography.bodySmall.copyWith(color: Colors.grey.shade700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAtStop ? Colors.green.shade100 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAtStop ? 'ARRIVED' : '~$etaMinutes min',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isAtStop ? Colors.green.shade900 : AppColors.studentAccent,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Stop progress step pills
                      if (progress != null) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.completedStopsCount / max(1, progress.totalStopsCount - 1),
                            backgroundColor: Colors.grey.shade200,
                            color: AppColors.studentAccent,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stop ${progress.completedStopsCount + 1} of ${progress.totalStopsCount}',
                              style: AppTypography.caption,
                            ),
                            Text(
                              '${location.speedKmh?.toInt() ?? 24} km/h',
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
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
}
