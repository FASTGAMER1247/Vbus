import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_typography.dart';
import 'student_providers.dart';

/// flow.md S3 — View my route and stops. Screens ST-9 (list) / ST-10
/// (stop detail, shown as an expansion here to keep the scaffold small).
class StudentRouteScreen extends ConsumerWidget {
  const StudentRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(myRouteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Route and stops')),
      body: routeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Something went wrong.')),
        data: (route) {
          if (route == null) return const Center(child: Text('Route not assigned yet.'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: route.stops.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final stop = route.stops[index];
              final isMine = index == route.stops.length - 1; // last stop stands in as "my stop" for the mock

              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: isMine ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  child: Text('${stop.order}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
                title: Text(stop.name, style: isMine ? AppTypography.body.copyWith(fontWeight: FontWeight.bold) : AppTypography.body),
                subtitle: stop.expectedTime != null ? Text('Expected ${stop.expectedTime}') : null,
                trailing: isMine ? const Icon(Icons.flag, color: Colors.deepOrange) : null,
              );
            },
          );
        },
      ),
    );
  }
}
