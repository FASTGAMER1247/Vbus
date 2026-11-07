import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/admin_models.dart';
import 'admin_providers.dart';

/// flow.md A1, MA-2 — College Directory with filters and search.
class CollegeListScreen extends ConsumerStatefulWidget {
  const CollegeListScreen({super.key});

  @override
  ConsumerState<CollegeListScreen> createState() => _CollegeListScreenState();
}

class _CollegeListScreenState extends ConsumerState<CollegeListScreen> {
  String _searchQuery = '';
  CollegeStatus? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final collegesAsync = ref.watch(collegesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colleges Directory'),
        backgroundColor: AppColors.masterAdminAccent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(collegesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.masterAdminAccent,
        icon: const Icon(Icons.add),
        label: const Text('Add College'),
        onPressed: () => context.push('/admin/colleges/new'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // Search & Filter header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search colleges by name, code, or city...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedStatusFilter == null,
                            onSelected: (_) => setState(() => _selectedStatusFilter = null),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Active'),
                            selected: _selectedStatusFilter == CollegeStatus.active,
                            onSelected: (_) => setState(() => _selectedStatusFilter = CollegeStatus.active),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Deactivated'),
                            selected: _selectedStatusFilter == CollegeStatus.deactivated,
                            onSelected: (_) => setState(() => _selectedStatusFilter = CollegeStatus.deactivated),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Archived'),
                            selected: _selectedStatusFilter == CollegeStatus.archived,
                            onSelected: (_) => setState(() => _selectedStatusFilter = CollegeStatus.archived),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Colleges List
              Expanded(
                child: collegesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading colleges: $e')),
                  data: (colleges) {
                    final filtered = colleges.where((college) {
                      if (_selectedStatusFilter != null && college.status != _selectedStatusFilter) {
                        return false;
                      }
                      if (_searchQuery.isNotEmpty) {
                        final matchesName = college.collegeName.toLowerCase().contains(_searchQuery);
                        final matchesCode = college.collegeCode.toLowerCase().contains(_searchQuery);
                        final matchesCity = college.city.toLowerCase().contains(_searchQuery);
                        return matchesName || matchesCode || matchesCity;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No colleges found matching criteria', style: AppTypography.heading),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final college = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push('/admin/colleges/${college.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.masterAdminAccent.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          college.collegeCode,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.masterAdminAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          college.collegeName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _StatusBadge(status: college.status),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${college.city}, ${college.state}', style: AppTypography.bodySmall),
                                      const Spacer(),
                                      const Icon(Icons.radar_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('Radius: ${college.campusRadiusMeters.toInt()}m', style: AppTypography.bodySmall),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text('${college.totalBuses} buses'),
                                        avatar: const Icon(Icons.directions_bus, size: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(college.feePolicy.label),
                                      ),
                                      const Spacer(),
                                      const Text('Details', style: TextStyle(color: AppColors.masterAdminAccent, fontWeight: FontWeight.bold)),
                                      const Icon(Icons.chevron_right, size: 18, color: AppColors.masterAdminAccent),
                                    ],
                                  ),
                                ],
                              ),
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

class _StatusBadge extends StatelessWidget {
  final CollegeStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case CollegeStatus.active:
        bg = AppColors.statusGood.withAlpha(35);
        fg = AppColors.statusGood;
        break;
      case CollegeStatus.deactivated:
        bg = AppColors.statusWarning.withAlpha(45);
        fg = Colors.orange.shade900;
        break;
      case CollegeStatus.archived:
        bg = Colors.grey.shade300;
        fg = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
