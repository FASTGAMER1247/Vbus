import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 2 — Driver list (Screen MG-4).
class DriverListScreen extends ConsumerWidget {
  const DriverListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: driversAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Could not load drivers.')),
            data: (drivers) {
              if (drivers.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 64, color: AppColors.lightTextSecondary),
                      SizedBox(height: 16),
                      Text('No drivers added yet', style: AppTypography.heading),
                      SizedBox(height: 8),
                      Text('Add drivers to assign them to your fleet and routes.'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: drivers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.managerAccent,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.person),
                      ),
                      title: Text(driver.name, style: AppTypography.heading),
                      subtitle: Text(driver.phone),
                      trailing: const Icon(Icons.chevron_right),
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
        label: const Text('Add Driver'),
        onPressed: () => context.push('/manager/drivers/new'),
      ),
    );
  }
}
