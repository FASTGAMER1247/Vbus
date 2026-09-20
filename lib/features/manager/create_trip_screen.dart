import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/manager_models.dart';
import '../../core/widgets/primary_button.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 5 — Schedule Today's Trip (Screen MG-12).
class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBusId;
  String? _selectedDriverId;
  String? _selectedRouteId;
  String _selectedShift = 'Morning';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final buses = ref.watch(busesProvider).value ?? [];
    final drivers = ref.watch(driversProvider).value ?? [];
    final routes = ref.watch(routesProvider).value ?? [];

    if (_selectedBusId == null && buses.isNotEmpty) _selectedBusId = buses.first.id;
    if (_selectedDriverId == null && drivers.isNotEmpty) _selectedDriverId = drivers.first.id;
    if (_selectedRouteId == null && routes.isNotEmpty) _selectedRouteId = routes.first.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Trip'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text('Trip Scheduling', style: AppTypography.heading),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a scheduled trip for today so the assigned driver can check in and start tracking.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 24),

                  // Bus selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBusId,
                    decoration: const InputDecoration(labelText: 'Bus *', border: OutlineInputBorder()),
                    items: buses
                        .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text('Bus ${b.busNumber} (${b.registrationNumber})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBusId = v),
                    validator: (v) => v == null ? 'Please select a bus' : null,
                  ),
                  const SizedBox(height: 16),

                  // Driver selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDriverId,
                    decoration: const InputDecoration(labelText: 'Driver *', border: OutlineInputBorder()),
                    items: drivers
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDriverId = v),
                    validator: (v) => v == null ? 'Please select a driver' : null,
                  ),
                  const SizedBox(height: 16),

                  // Route selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRouteId,
                    decoration: const InputDecoration(labelText: 'Route *', border: OutlineInputBorder()),
                    items: routes
                        .map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRouteId = v),
                    validator: (v) => v == null ? 'Please select a route' : null,
                  ),
                  const SizedBox(height: 16),

                  // Shift selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedShift,
                    decoration: const InputDecoration(labelText: 'Shift *', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Morning', child: Text('Morning Shift')),
                      DropdownMenuItem(value: 'Evening', child: Text('Evening Shift')),
                      DropdownMenuItem(value: 'Special/Exam', child: Text('Special / Exam Transport')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedShift = v);
                    },
                  ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: 'Schedule Trip',
                    accentColor: AppColors.managerAccent,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = ref.read(authControllerProvider);
    final collegeId = user?.collegeId ?? 'college-vjit';

    final params = CreateTripParams(
      collegeId: collegeId,
      busId: _selectedBusId!,
      driverId: _selectedDriverId!,
      routeId: _selectedRouteId!,
      shift: _selectedShift,
    );

    await ref.read(managerRepositoryProvider).createScheduledTrip(params);
    ref.invalidate(tripsProvider);
    ref.invalidate(fleetSummaryProvider);

    if (mounted) {
      context.pop();
    }
  }
}
