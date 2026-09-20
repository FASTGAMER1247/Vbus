import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/transport_models.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 1 — Bus list (Screen MG-2).
class BusListScreen extends ConsumerWidget {
  const BusListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busesAsync = ref.watch(busesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buses'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: busesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Could not load buses.')),
            data: (buses) {
              if (buses.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_bus_outlined, size: 64, color: AppColors.lightTextSecondary),
                      SizedBox(height: 16),
                      Text('No buses added yet', style: AppTypography.heading),
                      SizedBox(height: 8),
                      Text('Add your first vehicle to get started with fleet setup.'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: buses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bus = buses[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.managerAccent,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.directions_bus),
                      ),
                      title: Text('Bus ${bus.busNumber}', style: AppTypography.heading),
                      subtitle: Text('${bus.registrationNumber} · Capacity: ${bus.capacity} seats'),
                      trailing: IconButton(
                        icon: const Icon(Icons.qr_code_2),
                        tooltip: 'View Bus QR',
                        onPressed: () => _showQrDialog(context, bus),
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
        icon: const Icon(Icons.add),
        label: const Text('Add Bus'),
        onPressed: () => context.push('/manager/buses/new'),
      ),
    );
  }

  void _showQrDialog(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bus ${bus.busNumber} QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightBorder, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2, size: 100, color: Colors.black87),
                    const SizedBox(height: 8),
                    Text('BUS ID: ${bus.busNumber}', style: AppTypography.heading),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Drivers can scan this QR code or enter "${bus.busNumber}" to check in before starting a trip.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
