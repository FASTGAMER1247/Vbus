import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/trip_stage_badge.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 5 & M4 — Trip List & History (Screen MG-11).
class ManagerTripListScreen extends ConsumerWidget {
  const ManagerTripListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips & Reports'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: tripsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Could not load trips.')),
            data: (trips) {
              if (trips.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: AppColors.lightTextSecondary),
                      SizedBox(height: 16),
                      Text('No trips scheduled or recorded', style: AppTypography.heading),
                      SizedBox(height: 8),
                      Text('Schedule today\'s trips so drivers can begin tracking.'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  final startTimeStr = trip.startedAt != null
                      ? '${trip.startedAt!.hour.toString().padLeft(2, '0')}:${trip.startedAt!.minute.toString().padLeft(2, '0')}'
                      : 'Scheduled';

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.managerAccent,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.route),
                      ),
                      title: Text('${trip.route.name} · Bus ${trip.bus.busNumber}', style: AppTypography.heading),
                      subtitle: Text('Driver: ${trip.driver.name} · $startTimeStr'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TripStageBadge(stage: trip.stage),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => context.push('/manager/trips/${trip.id}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.managerAccent,
        icon: const Icon(Icons.add_road),
        label: const Text('Schedule Trip'),
        onPressed: () => context.push('/manager/trips/new'),
      ),
    );
  }
}
