import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/admin_models.dart';
import 'admin_providers.dart';

/// flow.md A1–A3, MA-1 — Master Admin platform dashboard & overview.
class MasterAdminHomeScreen extends ConsumerWidget {
  const MasterAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final summaryAsync = ref.watch(platformSummaryProvider);
    final collegesAsync = ref.watch(collegesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Administration'),
        backgroundColor: AppColors.masterAdminAccent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(platformSummaryProvider);
              ref.invalidate(collegesProvider);
            },
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Welcome, ${user?.name ?? 'Master Admin'}',
                  style: AppTypography.title),
              const SizedBox(height: 4),
              const Text(
                'Campus Transit Platform Command Center',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),

              // Platform Aggregate Metric Cards (prd.md Module 13)
              summaryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Card(
                  color: Colors.red.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Unable to load platform summary metrics.'),
                  ),
                ),
                data: (summary) => Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Colleges',
                        value: '${summary.totalColleges}',
                        color: AppColors.masterAdminAccent,
                        icon: Icons.school_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        title: 'Active',
                        value: '${summary.activeColleges}',
                        color: AppColors.statusGood,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        title: 'Managers',
                        value: '${summary.totalManagers}',
                        color: AppColors.managerAccent,
                        icon: Icons.manage_accounts_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Fleet',
                        value: '${summary.totalBuses}',
                        color: AppColors.driverAccent,
                        icon: Icons.directions_bus_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action shortcuts
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.masterAdminAccent,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('ONBOARD COLLEGE'),
                      onPressed: () => context.push('/admin/colleges/new'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('PROVISION MANAGER'),
                      onPressed: () => context.push('/admin/managers/new'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Registered Colleges Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Onboarded Colleges', style: AppTypography.heading),
                  TextButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('View All'),
                    onPressed: () => context.push('/admin/colleges'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              collegesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => const Text('Error loading colleges.'),
                data: (colleges) {
                  if (colleges.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No colleges registered yet.')),
                      ),
                    );
                  }

                  return Column(
                    children: colleges.map((college) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.masterAdminAccent.withAlpha(30),
                            foregroundColor: AppColors.masterAdminAccent,
                            child: Text(
                              college.collegeCode.isNotEmpty
                                  ? college.collegeCode.substring(0, 1)
                                  : 'C',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                college.collegeName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(status: college.status),
                            ],
                          ),
                          subtitle: Text(
                            '${college.city}, ${college.state} • ${college.totalBuses} buses • Geofence: ${college.campusRadiusMeters.toInt()}m',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push('/admin/colleges/${college.id}'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Directory Navigation Card
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform Directories',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.apartment_outlined,
                            color: AppColors.masterAdminAccent),
                        title: const Text('Manage Colleges & Geofences'),
                        subtitle: const Text(
                            'Configure campus boundaries, fee rules, and status'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/admin/colleges'),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge_outlined,
                            color: AppColors.managerAccent),
                        title: const Text('Manage Transport Managers'),
                        subtitle: const Text(
                            'Provision accounts, toggle active status, manage access'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/admin/managers'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final CollegeStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case CollegeStatus.active:
        bg = AppColors.statusGood.withAlpha(30);
        fg = AppColors.statusGood;
        break;
      case CollegeStatus.deactivated:
        bg = AppColors.statusWarning.withAlpha(40);
        fg = Colors.orange.shade900;
        break;
      case CollegeStatus.archived:
        bg = Colors.grey.shade300;
        fg = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
