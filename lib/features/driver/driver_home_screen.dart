import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import 'driver_providers.dart';

/// flow.md D1 — screen DR-1. Shows the driver's assigned bus/route
/// summary and a Start button. Tapping Start walks through the
/// permission check (D1 branch) before identifying the bus.
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final flow = ref.watch(driverFlowProvider);
    final trip = flow.scheduledTrip;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver'),
        backgroundColor: AppColors.driverAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, ${user?.name ?? ''}', style: AppTypography.title),
            const SizedBox(height: 24),
            if (trip == null)
              const Center(child: CircularProgressIndicator())
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${trip.route.name} · Bus ${trip.bus.busNumber}',
                          style: AppTypography.heading),
                      const SizedBox(height: 4),
                      const Text('No trip started yet', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            PrimaryButton(
              label: 'Start trip',
              accentColor: AppColors.driverAccent,
              onPressed: trip == null
                  ? null
                  : () {
                      // flow.md D1: permission check happens before
                      // identifying the bus, only on the first trip.
                      if (!flow.permissionsGranted) {
                        context.push('/driver/permissions');
                      } else {
                        context.push('/driver/identify');
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
