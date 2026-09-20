import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'manager_providers.dart';

/// flow.md M2 — Manager home & fleet dashboard (Screen MG-1).
/// Shows summary metrics, quick actions, setup sequence, and recent trips.
class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final summaryAsync = ref.watch(fleetSummaryProvider);
    final busesAsync = ref.watch(busesProvider);
    final driversAsync = ref.watch(driversProvider);
    final routesAsync = ref.watch(routesProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${user?.collegeName ?? 'College'} Transport'),
        backgroundColor: AppColors.managerAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(fleetSummaryProvider);
              ref.invalidate(busesProvider);
              ref.invalidate(driversProvider);
              ref.invalidate(routesProvider);
              ref.invalidate(assignmentsProvider);
              ref.invalidate(tripsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Welcome, ${user?.name ?? 'Manager'}', style: AppTypography.title),
              const SizedBox(height: 4),
              const Text('Overview & Fleet Operations', style: AppTypography.bodySmall),
              const SizedBox(height: 16),

              // Summary metric cards (flow.md M2)
              summaryAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )),
                error: (e, _) => const Text('Could not load fleet metrics.'),
                data: (summary) => Row(
                  children: [
                    Expanded(child: _MetricCard('Active Buses', '${summary.activeBuses}', AppColors.statusGood)),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricCard('Offline', '${summary.offlineBuses}', summary.offlineBuses > 0 ? AppColors.statusWarning : AppColors.lightTextSecondary)),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricCard('Completed', '${summary.completedTrips}', AppColors.statusInfo)),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricCard('Total Fleet', '${summary.totalBuses}', AppColors.managerAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick action: Live Fleet Map
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.managerAccent,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('OPEN LIVE FLEET MAP', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.push('/manager/fleet'),
              ),
              const SizedBox(height: 24),

              // Setup Checklist (flow.md M1)
              const Text('Setup Sequence', style: AppTypography.heading),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.managerAccent, foregroundColor: Colors.white, child: Text('1')),
                      title: const Text('Buses'),
                      subtitle: Text('${busesAsync.value?.length ?? 0} registered'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/manager/buses'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.managerAccent, foregroundColor: Colors.white, child: Text('2')),
                      title: const Text('Drivers'),
                      subtitle: Text('${driversAsync.value?.length ?? 0} registered'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/manager/drivers'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.managerAccent, foregroundColor: Colors.white, child: Text('3')),
                      title: const Text('Routes & Stops'),
                      subtitle: Text('${routesAsync.value?.length ?? 0} routes created'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/manager/routes'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.managerAccent, foregroundColor: Colors.white, child: Text('4')),
                      title: const Text('Assignments'),
                      subtitle: Text('${assignmentsAsync.value?.length ?? 0} active assignments'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/manager/assignments'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Trips & Reports Section (flow.md M1 Step 5, M4)
              const Text('Trips & Operational Reports', style: AppTypography.heading),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history, color: AppColors.managerAccent),
                  title: const Text('Trip List & Summaries'),
                  subtitle: const Text('View scheduled, active & past trips, or end stuck trips'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/manager/trips'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: AppTypography.display.copyWith(color: color, fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.caption, textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }
}
