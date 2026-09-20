import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/manager_models.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 4 — Assignments (Screen MG-8).
/// Maps Driver <-> Bus <-> Route. Rule: Only one active assignment per bus at a time.
class AssignmentScreen extends ConsumerWidget {
  const AssignmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final busesAsync = ref.watch(busesProvider);
    final driversAsync = ref.watch(driversProvider);
    final routesAsync = ref.watch(routesProvider);

    final buses = busesAsync.value ?? [];
    final drivers = driversAsync.value ?? [];
    final routes = routesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Assignments'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: assignmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Could not load assignments.')),
            data: (assignments) {
              if (assignments.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_off, size: 64, color: AppColors.lightTextSecondary),
                      SizedBox(height: 16),
                      Text('No assignments yet', style: AppTypography.heading),
                      SizedBox(height: 8),
                      Text('Assign drivers and routes to your buses to prepare for trips.'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  final bus = buses.cast().firstWhere((b) => b.id == assignment.busId, orElse: () => null);
                  final driver = drivers.cast().firstWhere((d) => d.id == assignment.driverId, orElse: () => null);
                  final route = routes.cast().firstWhere((r) => r.id == assignment.routeId, orElse: () => null);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.managerAccent,
                                foregroundColor: Colors.white,
                                child: Icon(Icons.directions_bus),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bus ${bus?.busNumber ?? assignment.busId}', style: AppTypography.heading),
                                    Text(bus?.registrationNumber ?? '', style: AppTypography.caption),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.statusCritical),
                                onPressed: () async {
                                  await ref.read(managerRepositoryProvider).deleteAssignment(assignment.id);
                                  ref.invalidate(assignmentsProvider);
                                  ref.invalidate(fleetSummaryProvider);
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _infoColumn('Assigned Driver', driver?.name ?? assignment.driverId, Icons.person_outline),
                              ),
                              Expanded(
                                child: _infoColumn('Assigned Route', route?.name ?? assignment.routeId, Icons.alt_route),
                              ),
                            ],
                          ),
                        ],
                      ),
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
        icon: const Icon(Icons.add_link),
        label: const Text('New Assignment'),
        onPressed: (buses.isEmpty || drivers.isEmpty || routes.isEmpty)
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add at least 1 bus, 1 driver, and 1 route before creating assignments.')),
                );
              }
            : () => _showNewAssignmentDialog(context, ref, buses, drivers, routes),
      ),
    );
  }

  Widget _infoColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.lightTextSecondary),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showNewAssignmentDialog(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> buses,
    List<dynamic> drivers,
    List<dynamic> routes,
  ) {
    var selectedBusId = buses.first.id as String;
    var selectedDriverId = drivers.first.id as String;
    var selectedRouteId = routes.first.id as String;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Fleet Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedBusId,
                decoration: const InputDecoration(labelText: 'Select Bus', border: OutlineInputBorder()),
                items: buses
                    .map((b) => DropdownMenuItem<String>(
                          value: b.id as String,
                          child: Text('Bus ${b.busNumber} (${b.registrationNumber})'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedBusId = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedDriverId,
                decoration: const InputDecoration(labelText: 'Select Driver', border: OutlineInputBorder()),
                items: drivers
                    .map((d) => DropdownMenuItem<String>(
                          value: d.id as String,
                          child: Text(d.name as String),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedDriverId = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRouteId,
                decoration: const InputDecoration(labelText: 'Select Route', border: OutlineInputBorder()),
                items: routes
                    .map((r) => DropdownMenuItem<String>(
                          value: r.id as String,
                          child: Text(r.name as String),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedRouteId = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final user = ref.read(authControllerProvider);
                final collegeId = user?.collegeId ?? 'college-vjit';

                final assignment = FleetAssignment(
                  id: 'assign-${DateTime.now().millisecondsSinceEpoch}',
                  collegeId: collegeId,
                  busId: selectedBusId,
                  driverId: selectedDriverId,
                  routeId: selectedRouteId,
                  assignedAt: DateTime.now(),
                );

                await ref.read(managerRepositoryProvider).saveAssignment(assignment);
                ref.invalidate(assignmentsProvider);
                ref.invalidate(fleetSummaryProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}
