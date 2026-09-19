import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';

/// Stub. Next up: M1 (setup: buses/drivers/routes/assignments), M2
/// (live fleet), M3 (tracking unavailable), M4 (trip summary), M5 (end
/// a stuck trip). Screens MG-1 through MG-14 in design.md §5.4 — the
/// biggest single chunk of frontend work per the earlier team split.
class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        backgroundColor: AppColors.managerAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Text('Hi ${user?.name ?? ''} — manager flow (M1–M5) goes here.'),
      ),
    );
  }
}
