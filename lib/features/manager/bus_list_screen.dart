import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/bus_qr_dialog.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 1 — Bus list (Screen MG-2).
class BusListScreen extends ConsumerWidget {
  const BusListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busesAsync = ref.watch(busesProvider);
    final user = ref.watch(authControllerProvider);
    final collegeId = user?.collegeId ?? 'college-vjit';
    final collegeName = user?.collegeName ?? 'College Transport Operations';

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
                        tooltip: 'View Official QR Sticker',
                        onPressed: () => showBusQrDialog(
                          context,
                          bus: bus,
                          collegeId: collegeId,
                          collegeName: collegeName,
                        ),
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
}
