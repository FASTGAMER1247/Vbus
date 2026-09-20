import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/manager_models.dart';
import '../../core/widgets/freshness_label.dart';
import '../../core/widgets/trip_stage_badge.dart';
import 'manager_providers.dart';

/// flow.md M2 & M3 — Manager Live Fleet Map & Watchdog (Screens MG-9, MG-10).
class ManagerLiveFleetScreen extends ConsumerStatefulWidget {
  const ManagerLiveFleetScreen({super.key});

  @override
  ConsumerState<ManagerLiveFleetScreen> createState() => _ManagerLiveFleetScreenState();
}

class _ManagerLiveFleetScreenState extends ConsumerState<ManagerLiveFleetScreen> {
  String _filter = 'All'; // 'All', 'Active', 'Offline', 'Inactive'

  @override
  Widget build(BuildContext context) {
    final fleetAsync = ref.watch(liveFleetLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Fleet Map'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: fleetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load live fleet.')),
        data: (fleet) {
          final filteredFleet = fleet.where((b) {
            if (_filter == 'Active') return b.activeTrip != null && !b.isOffline;
            if (_filter == 'Offline') return b.isOffline;
            if (_filter == 'Inactive') return b.activeTrip == null;
            return true;
          }).toList();

          // Find first available bus coordinate or fallback to VJIT Hyderabad
          final firstCoord = fleet
              .where((b) => b.location != null)
              .map((b) => LatLng(b.location!.latitude, b.location!.longitude))
              .firstOrNull ??
              const LatLng(17.4374, 78.4487);

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: firstCoord,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.campus_transit',
                  ),
                  MarkerLayer(
                    markers: filteredFleet
                        .where((b) => b.location != null)
                        .map((b) {
                      final p = LatLng(b.location!.latitude, b.location!.longitude);
                      final markerColor = b.isOffline
                          ? AppColors.statusWarning
                          : (b.activeTrip != null ? AppColors.statusGood : AppColors.statusUnavailable);

                      return Marker(
                        point: p,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _showBusDetailsSheet(context, b),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: markerColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Transform.rotate(
                                  angle: ((b.location?.headingDegrees ?? 0) * 3.14159 / 180),
                                  child: const Icon(Icons.directions_bus, color: Colors.white, size: 22),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    b.bus.busNumber,
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Filter Chips overlay at the top
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Active', 'Offline', 'Inactive'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: selected,
                          selectedColor: AppColors.managerAccent.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.managerAccent,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Bottom status legend
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _legendDot('Active', AppColors.statusGood),
                        _legendDot('Offline / Stale', AppColors.statusWarning),
                        _legendDot('Inactive', AppColors.statusUnavailable),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  void _showBusDetailsSheet(BuildContext context, FleetBusLocation b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bus ${b.bus.busNumber}', style: AppTypography.title),
                    Text(b.bus.registrationNumber ?? '', style: AppTypography.caption),
                  ],
                ),
                if (b.activeTrip != null) TripStageBadge(stage: b.activeTrip!.stage),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Route and Driver
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Route', style: AppTypography.caption),
                      Text(b.route?.name ?? 'Not assigned', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Driver', style: AppTypography.caption),
                      Text(b.driver?.name ?? 'Not assigned', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Telemetry & Health Panel (flow.md M2 & M3)
            if (b.health != null && b.location != null) ...[
              const Text('Device & Telemetry', style: AppTypography.heading),
              const SizedBox(height: 8),
              if (b.isOffline)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusWarning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.statusWarning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tracking unavailable · Last known location shown. (Possible signal loss or app closed)',
                          style: AppTypography.caption.copyWith(color: AppColors.statusWarning, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Speed: ${b.location!.speedKmh?.toStringAsFixed(0) ?? '0'} km/h', style: AppTypography.bodySmall),
                  Text('Battery: ${b.health!.batteryPercent}%', style: AppTypography.bodySmall),
                  Text('GPS: ${b.health!.gps.name.toUpperCase()}', style: AppTypography.bodySmall),
                  FreshnessLabel(updatedAt: b.location!.updatedAt),
                ],
              ),
              const SizedBox(height: 16),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No active trip in progress for this bus.', style: AppTypography.bodySmall),
              ),

            // Action: View Trip
            if (b.activeTrip != null)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.managerAccent),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/manager/trips/${b.activeTrip!.id}');
                },
                child: const Text('View Trip Details & Controls'),
              ),
          ],
        ),
      ),
    );
  }
}
