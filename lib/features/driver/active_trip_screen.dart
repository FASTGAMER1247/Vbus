import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/driver_models.dart';
import '../../core/widgets/trip_stage_badge.dart';
import 'driver_providers.dart';

/// flow.md D2 (During a trip) + D3 (Offline) + D4 Path B (manual end, DR-8 confirmation).
/// Screen DR-6: Big text, few elements, glanceable while driving.
class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(driverFlowProvider);
    final trip = flowState.activeTrip;
    final healthAsync = ref.watch(driverDeviceHealthProvider);

    if (trip == null) {
      return const Scaffold(body: Center(child: Text('No active trip.')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Live Trip HUD'),
        backgroundColor: AppColors.driverAccent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${trip.route.name} · Bus ${trip.bus.busNumber}',
                      style: AppTypography.driverPrimary,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (flowState.isUnassignedTakeover)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'Takeover',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TripStageBadge(stage: trip.stage),
                  const Spacer(),
                  if (flowState.advisoryDocumentAlert != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, size: 14, color: Colors.amber.shade900),
                          const SizedBox(width: 4),
                          Text(
                            'Doc Notice',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Device health & Telemetry panel
              healthAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const Text('Health status unavailable.'),
                data: (health) => _HealthPanel(health: health),
              ),

              const Spacer(),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusCritical,
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => _confirmEndTrip(context, ref, healthAsync.value),
                child: const Text('END TRIP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmEndTrip(
    BuildContext context,
    WidgetRef ref,
    DriverDeviceHealth? health,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this trip?'),
        content: const Text('This will complete tracking and notify waiting students and managers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusCritical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm End'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Check geofence status: If distance to campus is < 300m, automatically marked as at college
    final dist = health?.distanceToCampusMeters;
    final autoAtCollege = dist != null && dist <= 300.0;

    bool insideGeofence = autoAtCollege;
    if (!autoAtCollege && context.mounted) {
      final promptInside = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Campus Geofence Check'),
          content: Text(
            dist != null
                ? 'Current GPS distance to campus is ${(dist / 1000).toStringAsFixed(1)} km.\nAre you physically at the college campus?'
                : 'Are you physically inside the college campus?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, Ending Outside'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, At Campus'),
            ),
          ],
        ),
      );
      if (promptInside == null || !context.mounted) return;
      insideGeofence = promptInside;
    }

    await ref.read(driverFlowProvider.notifier).endTripManually(insideGeofence: insideGeofence);
    if (context.mounted) context.go('/driver/completed');
  }
}

class _HealthPanel extends StatelessWidget {
  final DriverDeviceHealth health;
  const _HealthPanel({required this.health});

  @override
  Widget build(BuildContext context) {
    final dist = health.distanceToCampusMeters;
    final isInsideGeofence = dist != null && dist <= 300.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Geofence Banner
        if (isInsideGeofence)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.statusGood, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Campus Geofence Reached (${dist.toInt()}m) — Trip ready for arrival completion',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Offline / Battery warnings
        if (health.network == NetworkStatus.offline)
          _banner(context, 'Offline. GPS points queued on device.', AppColors.statusUnavailable),
        if (health.isBatteryCritical)
          _banner(context, 'Battery critical (${health.batteryPercent}%). Tracking may stop.', AppColors.statusCritical)
        else if (health.isBatteryLow)
          _banner(context, 'Battery ${health.batteryPercent}%. Please connect phone to charger.', AppColors.statusWarning),

        // Telemetry cards grid
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Speed',
                value: '${health.currentSpeedKmh?.toInt() ?? 0} km/h',
                icon: Icons.speed,
                color: AppColors.driverAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'To Campus',
                value: dist != null ? (dist > 1000 ? '${(dist / 1000).toStringAsFixed(1)} km' : '${dist.toInt()} m') : '--',
                icon: Icons.radar,
                color: isInsideGeofence ? AppColors.statusGood : AppColors.managerAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'Battery',
                value: '${health.batteryPercent}%',
                icon: Icons.battery_charging_full,
                color: health.isBatteryLow ? AppColors.statusWarning : AppColors.statusGood,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                _statRow('GPS Fix', _gpsLabel(health.gps), _gpsColor(health.gps)),
                const Divider(height: 8),
                _statRow('Network Sync', _networkLabel(health.network), _networkColor(health.network)),
                const Divider(height: 8),
                _statRow('Last Server Heartbeat', _agoLabel(health.lastSyncAt), AppColors.lightTextSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner(BuildContext context, String text, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
      );

  Widget _statRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall),
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
