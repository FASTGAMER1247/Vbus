import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/trip_stage_badge.dart';
import 'manager_providers.dart';

/// flow.md M4 & M5 — Trip Summary & End Stuck Trip (Screens MG-13, MG-14).
class TripSummaryScreen extends ConsumerWidget {
  final String tripId;
  const TripSummaryScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Summary'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: tripAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Could not load trip details.')),
            data: (trip) {
              if (trip == null) {
                return const Center(child: Text('Trip not found.'));
              }

              final durationStr = (trip.startedAt != null && trip.completedAt != null)
                  ? '${trip.completedAt!.difference(trip.startedAt!).inMinutes} mins'
                  : (trip.startedAt != null
                      ? '${DateTime.now().difference(trip.startedAt!).inMinutes} mins (in progress)'
                      : 'Not started');

              final isStuckOrActive = trip.stage.isActive;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(trip.route.name, style: AppTypography.title),
                      TripStageBadge(stage: trip.stage),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Bus ${trip.bus.busNumber} (${trip.bus.registrationNumber})', style: AppTypography.bodySmall),
                  const SizedBox(height: 20),

                  // Metrics summary card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _row('Driver', trip.driver.name),
                          const Divider(),
                          _row('Start Time', trip.startedAt != null ? _fmt(trip.startedAt!) : '—'),
                          const Divider(),
                          _row('End Time', trip.completedAt != null ? _fmt(trip.completedAt!) : (trip.startedAt != null ? 'Active' : 'Scheduled')),
                          const Divider(),
                          _row('Duration', durationStr),
                          const Divider(),
                          _row('Distance', trip.route.estimatedDistanceKm != null ? '~${trip.route.estimatedDistanceKm!.toStringAsFixed(1)} km' : '—'),
                          const Divider(),
                          _row('Stops Covered', '${trip.route.stops.length} stops'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // End stuck trip action (flow.md M5)
                  if (isStuckOrActive) ...[
                    const Text(
                      'Trip Resolution Controls',
                      style: AppTypography.heading,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If this bus has completed its journey outside the geofence, or the driver app was closed, '
                      'you can terminate this trip to release the bus for new assignments.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.statusCritical,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('END STUCK TRIP (MANAGER OVERRIDE)'),
                      onPressed: () => _confirmEndStuckTrip(context, ref, trip.id),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmEndStuckTrip(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this stuck trip?'),
        content: const Text(
          'This will mark the trip as ended manually by manager. It will be recorded who ended it and when. '
          'The bus will immediately become available for new trips.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusCritical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm & End Trip'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final user = ref.read(authControllerProvider);
      await ref.read(managerRepositoryProvider).endStuckTrip(
            tripId: id,
            managerId: user?.id ?? 'manager-1',
          );
      ref.invalidate(tripDetailProvider(id));
      ref.invalidate(tripsProvider);
      ref.invalidate(fleetSummaryProvider);
      ref.invalidate(liveFleetLocationsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip ended by manager override.')),
        );
      }
    }
  }
}
