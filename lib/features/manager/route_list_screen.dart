import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 3 — Route list (Screen MG-6).
class RouteListScreen extends ConsumerWidget {
  const RouteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes & Stops'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: routesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Could not load routes.')),
            data: (routes) {
              if (routes.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alt_route, size: 64, color: AppColors.lightTextSecondary),
                      SizedBox(height: 16),
                      Text('No routes created yet', style: AppTypography.heading),
                      SizedBox(height: 8),
                      Text('Create routes and add sequential pickup stops.'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: routes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final route = routes[index];
                  final distStr = route.estimatedDistanceKm != null
                      ? '~${route.estimatedDistanceKm!.toStringAsFixed(1)} km'
                      : 'Distance uncalculated';
                  final durStr = route.expectedDuration != null
                      ? '${route.expectedDuration!.inMinutes} mins'
                      : '—';

                  return Card(
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.managerAccent,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.alt_route),
                      ),
                      title: Text(route.name, style: AppTypography.heading),
                      subtitle: Text('${route.stops.length} stops · $distStr · $durStr'),
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ordered Stops:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...route.stops.map(
                                (stop) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppColors.managerAccent.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text('${stop.order}', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.managerAccent)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(stop.name, style: AppTypography.body)),
                                      if (stop.expectedTime != null)
                                        Text(stop.expectedTime!, style: AppTypography.caption.copyWith(color: AppColors.lightTextSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
        label: const Text('Add Route'),
        onPressed: () => context.push('/manager/routes/new'),
      ),
    );
  }
}
