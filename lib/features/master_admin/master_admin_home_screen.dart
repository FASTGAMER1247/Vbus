import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';

/// Stub. Next up: A1 (create/configure a college), A2 (create a
/// manager account), A3 (activate/deactivate/archive). Screens MA-1
/// through MA-6 in design.md §5.5.
class MasterAdminHomeScreen extends ConsumerWidget {
  const MasterAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Admin'),
        backgroundColor: AppColors.masterAdminAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Text('Hi ${user?.name ?? ''} — master admin flow (A1–A3) goes here.'),
      ),
    );
  }
}
