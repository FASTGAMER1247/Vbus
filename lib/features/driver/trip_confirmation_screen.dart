import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import 'driver_providers.dart';

/// flow.md D1 — screen DR-5. Layout follows design.md §11.4:
/// Driver → Bus → Route → College → Shift, then Start Trip.
class TripConfirmationScreen extends ConsumerWidget {
  const TripConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final trip = ref.watch(driverFlowProvider).scheduledTrip;
    final isLoading = ref.watch(driverFlowProvider).isLoading;

    if (trip == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.driverAccent, title: const Text('Confirm your trip')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Driver', user?.name ?? trip.driver.name),
            _row('Bus', trip.bus.busNumber),
            _row('Route', trip.route.name),
            _row('College', user?.collegeName ?? ''),
            _row('Shift', 'Morning'), // shift concept isn't modeled yet — see prd.md §17 open question on multiple shifts
            const Spacer(),
            PrimaryButton(
              label: 'Start trip',
              accentColor: AppColors.driverAccent,
              isLoading: isLoading,
              onPressed: () async {
                await ref.read(driverFlowProvider.notifier).startTrip();
                if (context.mounted) context.go('/driver/active');
              },
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Not right? Go back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall),
            Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
