import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/transport_models.dart';
import '../../core/widgets/primary_button.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 3 — Route Builder with ordered stops (Screen MG-7).
class RouteBuilderScreen extends ConsumerStatefulWidget {
  const RouteBuilderScreen({super.key});

  @override
  ConsumerState<RouteBuilderScreen> createState() => _RouteBuilderScreenState();
}

class _RouteBuilderScreenState extends ConsumerState<RouteBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController(text: '15.0');
  final _durationController = TextEditingController(text: '45');
  final List<Stop> _stops = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with default college starting stop
    _stops.add(const Stop(
      id: 'stop-start',
      name: 'College Campus (Start)',
      latitude: 17.3912,
      longitude: 78.3204,
      order: 1,
      expectedTime: '7:00 AM',
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addStopDialog() {
    final stopNameController = TextEditingController();
    final timeController = TextEditingController(text: '7:30 AM');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stopNameController,
              decoration: const InputDecoration(
                labelText: 'Stop Name *',
                hintText: 'e.g. Gachibowli Junction',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Expected Time',
                hintText: 'e.g. 7:25 AM',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (stopNameController.text.trim().isEmpty) return;
              setState(() {
                final order = _stops.length + 1;
                // Offset coordinates slightly from previous stop
                final lastStop = _stops.last;
                _stops.add(Stop(
                  id: 'stop-${DateTime.now().millisecondsSinceEpoch}',
                  name: stopNameController.text.trim(),
                  latitude: lastStop.latitude + 0.008,
                  longitude: lastStop.longitude + 0.005,
                  order: order,
                  expectedTime: timeController.text.trim(),
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 stops to create a route.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = ref.read(authControllerProvider);
    final collegeId = user?.collegeId ?? 'college-vjit';

    final dist = double.tryParse(_distanceController.text.trim()) ?? 15.0;
    final durMins = int.tryParse(_durationController.text.trim()) ?? 45;

    // Update stop ordering numbers sequentially
    final reorderedStops = [
      for (var i = 0; i < _stops.length; i++)
        Stop(
          id: _stops[i].id,
          name: _stops[i].name,
          latitude: _stops[i].latitude,
          longitude: _stops[i].longitude,
          order: i + 1,
          expectedTime: _stops[i].expectedTime,
        ),
    ];

    final route = TransportRoute(
      id: 'route-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      stops: reorderedStops,
      estimatedDistanceKm: dist,
      expectedDuration: Duration(minutes: durMins),
    );

    await ref.read(managerRepositoryProvider).saveRoute(collegeId: collegeId, route: route);
    ref.invalidate(routesProvider);
    ref.invalidate(fleetSummaryProvider);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Route'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Route Details', style: AppTypography.heading),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Route Name *',
                    hintText: 'e.g. Route 9 - Gachibowli',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a route name' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Distance (km)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Expected Duration (mins)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sequential Stops (${_stops.length})', style: AppTypography.heading),
                    TextButton.icon(
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add Stop'),
                      onPressed: _addStopDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Drag stops to reorder. College -> Stop 1 -> ... -> Stop N.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stops.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final item = _stops.removeAt(oldIndex);
                        _stops.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final stop = _stops[index];
                      return ListTile(
                        key: ValueKey(stop.id),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.managerAccent,
                          foregroundColor: Colors.white,
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(stop.name, style: AppTypography.body),
                        subtitle: stop.expectedTime != null ? Text('Expected: ${stop.expectedTime}') : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_stops.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.statusCritical),
                                onPressed: () {
                                  setState(() => _stops.removeAt(index));
                                },
                              ),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Save Route',
                  accentColor: AppColors.managerAccent,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
