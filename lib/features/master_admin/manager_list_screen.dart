import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'admin_providers.dart';

/// flow.md A2, MA-6 — Platform-wide directory of college transport managers.
class AdminManagerListScreen extends ConsumerStatefulWidget {
  const AdminManagerListScreen({super.key});

  @override
  ConsumerState<AdminManagerListScreen> createState() => _AdminManagerListScreenState();
}

class _AdminManagerListScreenState extends ConsumerState<AdminManagerListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final managersAsync = ref.watch(adminManagersProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Managers Directory'),
        backgroundColor: AppColors.masterAdminAccent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminManagersProvider(null)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.masterAdminAccent,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Manager'),
        onPressed: () => context.push('/admin/managers/new'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search managers by name, email, or college...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: managersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (managers) {
                    final filtered = managers.where((m) {
                      if (_searchQuery.isEmpty) return true;
                      return m.name.toLowerCase().contains(_searchQuery) ||
                          m.email.toLowerCase().contains(_searchQuery) ||
                          m.collegeName.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No managers found', style: AppTypography.heading),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final manager = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: manager.isActive
                                  ? AppColors.managerAccent.withAlpha(35)
                                  : Colors.grey.shade200,
                              foregroundColor: manager.isActive ? AppColors.managerAccent : Colors.grey,
                              child: Text(
                                manager.name.isNotEmpty ? manager.name.substring(0, 1).toUpperCase() : 'M',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(manager.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text('${manager.email} • ${manager.phone}', style: AppTypography.caption),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    manager.collegeName,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  manager.isActive ? 'Active' : 'Disabled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: manager.isActive ? AppColors.statusGood : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: manager.isActive,
                                  activeTrackColor: AppColors.statusGood.withAlpha(100),
                                  activeThumbColor: AppColors.statusGood,
                                  onChanged: (val) async {
                                    await ref.read(adminRepositoryProvider).toggleManagerStatus(
                                          managerId: manager.id,
                                          isActive: val,
                                        );
                                    ref.invalidate(adminManagersProvider(null));
                                    ref.invalidate(platformSummaryProvider);
                                  },
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
            ],
          ),
        ),
      ),
    );
  }
}
