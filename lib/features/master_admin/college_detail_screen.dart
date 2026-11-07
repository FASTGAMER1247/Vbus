import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/admin_models.dart';
import 'admin_providers.dart';

/// flow.md A1–A3, MA-4 — College profile, geofence inspect, status change, and managers.
class CollegeDetailScreen extends ConsumerWidget {
  final String collegeId;

  const CollegeDetailScreen({super.key, required this.collegeId});

  Future<void> _showStatusDialog(BuildContext context, WidgetRef ref, College college) async {
    CollegeStatus selected = college.status;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String explanation = '';
            switch (selected) {
              case CollegeStatus.active:
                explanation = 'All users (students, faculty, drivers, managers) have full access to operations and live tracking.';
                break;
              case CollegeStatus.deactivated:
                explanation = 'Users of this college will be blocked from logging in. Ongoing operations and tracking are paused.';
                break;
              case CollegeStatus.archived:
                explanation = 'The college is kept read-only for historical records. No active sessions, trips, or modifications allowed.';
                break;
            }

            return AlertDialog(
              title: const Text('Change College Status (flow.md A3)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select target operational status:'),
                  const SizedBox(height: 12),
                  ...CollegeStatus.values.map((s) {
                    final isSelected = selected == s;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setDialogState(() => selected = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.masterAdminAccent : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppColors.masterAdminAccent : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      s == CollegeStatus.active
                                          ? 'Normal live operations'
                                          : s == CollegeStatus.deactivated
                                              ? 'Block login for all users'
                                              : 'Read-only records',
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected == CollegeStatus.active ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected == CollegeStatus.active ? Colors.green.shade300 : Colors.amber.shade300,
                      ),
                    ),
                    child: Text(
                      'Impact: $explanation',
                      style: TextStyle(
                        fontSize: 12,
                        color: selected == CollegeStatus.active ? Colors.green.shade900 : Colors.brown.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: selected == CollegeStatus.active
                        ? AppColors.statusGood
                        : AppColors.masterAdminAccent,
                  ),
                  onPressed: () async {
                    await ref.read(adminRepositoryProvider).setCollegeStatus(college.id, selected);
                    ref.invalidate(collegeDetailProvider(college.id));
                    ref.invalidate(collegesProvider);
                    ref.invalidate(platformSummaryProvider);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('College status changed to ${selected.label}')),
                      );
                    }
                  },
                  child: const Text('Confirm Status Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegeAsync = ref.watch(collegeDetailProvider(collegeId));
    final managersAsync = ref.watch(adminManagersProvider(collegeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('College Profile'),
        backgroundColor: AppColors.masterAdminAccent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(collegeDetailProvider(collegeId));
              ref.invalidate(adminManagersProvider(collegeId));
            },
          ),
          IconButton(
            tooltip: 'Edit Settings',
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/admin/colleges/$collegeId/edit'),
          ),
        ],
      ),
      body: collegeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (college) {
          if (college == null) {
            return const Center(child: Text('College not found.'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // College Header Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.masterAdminAccent.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  college.collegeCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.masterAdminAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(college.collegeName, style: AppTypography.heading),
                                    const SizedBox(height: 4),
                                    Text('${college.city}, ${college.state}', style: AppTypography.bodySmall),
                                    const SizedBox(height: 2),
                                    Text('Domain: ${college.emailDomain ?? 'None'}', style: AppTypography.caption),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.sync_alt, size: 16),
                                label: Text(college.status.label),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: college.status == CollegeStatus.active
                                      ? AppColors.statusGood
                                      : Colors.orange.shade800,
                                ),
                                onPressed: () => _showStatusDialog(context, ref, college),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _DetailStat('Total Buses', '${college.totalBuses}', Icons.directions_bus),
                              _DetailStat('Total Drivers', '${college.totalDrivers}', Icons.badge),
                              _DetailStat('Students Enrolled', '${college.totalStudents}', Icons.group),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campus Geofence & Location Card (flow.md A1)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Campus Geofence & Boundary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Radius: ${college.campusRadiusMeters.toInt()}m',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.gps_fixed, color: AppColors.masterAdminAccent),
                            title: Text('Campus Coordinates: ${college.campusLatitude.toStringAsFixed(4)}, ${college.campusLongitude.toStringAsFixed(4)}'),
                            subtitle: const Text('Used by the automated geofence system to detect bus entry/departure'),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.policy_outlined, color: AppColors.managerAccent),
                            title: const Text('Transport Fee Compliance Policy'),
                            subtitle: Text(college.feePolicy.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // College Managers Section (flow.md A2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('College Administrators & Managers', style: AppTypography.heading),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.managerAccent,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Add Manager'),
                        onPressed: () => context.push('/admin/colleges/$collegeId/managers/new'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  managersAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text('Error loading managers: $e'),
                    data: (managers) {
                      if (managers.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.person_off_outlined, size: 36, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  const Text('No transport managers assigned yet.'),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => context.push('/admin/colleges/$collegeId/managers/new'),
                                    child: const Text('Create First Manager Account'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: managers.map((manager) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: manager.isActive ? AppColors.managerAccent.withAlpha(35) : Colors.grey.shade200,
                                foregroundColor: manager.isActive ? AppColors.managerAccent : Colors.grey,
                                child: const Icon(Icons.person),
                              ),
                              title: Text(manager.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${manager.email} • ${manager.phone}'),
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
                                  const SizedBox(width: 6),
                                  Switch(
                                    value: manager.isActive,
                                    activeThumbColor: AppColors.statusGood,
                                    onChanged: (val) async {
                                      await ref.read(adminRepositoryProvider).toggleManagerStatus(
                                            managerId: manager.id,
                                            isActive: val,
                                          );
                                      ref.invalidate(adminManagersProvider(collegeId));
                                      ref.invalidate(adminManagersProvider(null));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
