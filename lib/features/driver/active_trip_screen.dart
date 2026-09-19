import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/driver_models.dart';
import '../../core/widgets/trip_stage_badge.dart';
import 'driver_providers.dart';

/// flow.md D2 (During a trip) + D3 (Offline) + D4 Path B (manual end,
/// DR-8 confirmation). Screen DR-6. Layout follows design.md §11.3:
/// big text, few elements, no scrolling — "the driver should not need
/// to interact while driving."
class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(driverFlowProvider).activeTrip;
    final healthAsync = ref.watch(driverDeviceHealthProvider);

    if (trip == null) {
      return const Scaffold(body: Center(child: Text('No active trip.')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${trip.route.name} · Bus ${trip.bus.busNumber}', style: AppTypography.driverPrimary),
              const SizedBox(height: 8),
              TripStageBadge(stage: trip.stage),
              const SizedBox(height: 24),
              healthAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => const Text('Health status unavailable.'),
                data: (health) => _HealthPanel(health: health),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusCritical,
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => _confirmEndTrip(context, ref),
                child: const Text('END TRIP', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmEndTrip(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this trip?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // flow.md D4 Path B: "Bus inside the college geofence?" decides the
    // wording. No real geofence yet (BACKEND_CHANGES.md #3), so the
    // driver answers directly for the demo build.
    final insideGeofence = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you at the college?'),
        content: const Text('This decides how the trip is marked as ended.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No, ending outside')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, at college')),
        ],
      ),
    );
    if (insideGeofence == null || !context.mounted) return;

    await ref.read(driverFlowProvider.notifier).endTripManually(insideGeofence: insideGeofence);
    if (context.mounted) context.go('/driver/completed');
  }
}

class _HealthPanel extends StatelessWidget {
  final DriverDeviceHealth health;
  const _HealthPanel({required this.health});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // D3: offline banner
        if (health.network == NetworkStatus.offline)
          _banner(context, 'Offline. Tracking continues.', AppColors.statusUnavailable),
        if (health.isBatteryCritical)
          _banner(context, 'Battery critical. Tracking may stop soon.', AppColors.statusCritical)
        else if (health.isBatteryLow)
          _banner(context, 'Battery ${health.batteryPercent}%. Tracking is active. Please connect charger.',
              AppColors.statusWarning),
        if (health.gps == GpsStatus.weak || health.gps == GpsStatus.unavailable)
          _banner(context, 'GPS weak — using last known location.', AppColors.statusWarning),
        const SizedBox(height: 8),
        _statRow('GPS', _gpsLabel(health.gps), _gpsColor(health.gps)),
        _statRow('Network', _networkLabel(health.network), _networkColor(health.network)),
        _statRow('Battery', '${health.batteryPercent}%',
            health.isBatteryCritical ? AppColors.statusCritical : (health.isBatteryLow ? AppColors.statusWarning : AppColors.statusGood)),
        _statRow('Last sync', _agoLabel(health.lastSyncAt), AppColors.lightTextSecondary),
      ],
    );
  }

  Widget _banner(BuildContext context, String text, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: AppTypography.bodySmall.copyWith(color: color)),
      );

  Widget _statRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body),
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      );

  String _gpsLabel(GpsStatus s) => switch (s) {
        GpsStatus.active => 'Active',
        GpsStatus.weak => 'Weak',
        GpsStatus.unavailable => 'Unavailable',
      };
  Color _gpsColor(GpsStatus s) => switch (s) {
        GpsStatus.active => AppColors.statusGood,
        GpsStatus.weak => AppColors.statusWarning,
        GpsStatus.unavailable => AppColors.statusCritical,
      };
  String _networkLabel(NetworkStatus s) => switch (s) {
        NetworkStatus.online => 'Online',
        NetworkStatus.weak => 'Weak',
        NetworkStatus.offline => 'Offline',
      };
  Color _networkColor(NetworkStatus s) => switch (s) {
        NetworkStatus.online => AppColors.statusGood,
        NetworkStatus.weak => AppColors.statusWarning,
        NetworkStatus.offline => AppColors.statusUnavailable,
      };
  String _agoLabel(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    return s < 60 ? '${s}s ago' : '${(s / 60).floor()}m ago';
  }
}
