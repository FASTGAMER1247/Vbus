import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import 'driver_providers.dart';

/// flow.md D4 Path A/B — screen DR-9. "Driver sees 'Trip completed' +
/// short summary" then returns to Driver home.
class TripCompletedScreen extends ConsumerWidget {
  const TripCompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(lastCompletedTripProvider);

    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.driverAccent, title: const Text('Trip completed')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, color: AppColors.statusGood, size: 56),
            const SizedBox(height: 16),
            const Text('Trip completed.', style: AppTypography.title),
            const SizedBox(height: 24),
            if (trip != null) ...[
              _row('Route', trip.route.name),
              _row('Bus', trip.bus.busNumber),
              if (trip.startedAt != null) _row('Started', _fmt(trip.startedAt!)),
              if (trip.completedAt != null) _row('Ended', _fmt(trip.completedAt!)),
              if (trip.startedAt != null && trip.completedAt != null)
                _row('Duration', _duration(trip.completedAt!.difference(trip.startedAt!))),
            ],
            const Spacer(),
            PrimaryButton(
              label: 'Back to home',
              accentColor: AppColors.driverAccent,
              onPressed: () => context.go('/driver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: AppTypography.bodySmall), Text(value, style: AppTypography.body)],
        ),
      );

  String _fmt(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _duration(Duration d) => '${d.inMinutes}m';
}
