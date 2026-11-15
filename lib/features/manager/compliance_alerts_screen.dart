import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'manager_providers.dart';

/// flow.md M2 / prd.md Module 14 — Manager Fleet Compliance & Document Expiry Watchdog.
class ComplianceAlertsScreen extends ConsumerStatefulWidget {
  const ComplianceAlertsScreen({super.key});

  @override
  ConsumerState<ComplianceAlertsScreen> createState() => _ComplianceAlertsScreenState();
}

class _ComplianceAlertsScreenState extends ConsumerState<ComplianceAlertsScreen> {
  String _filter = 'All'; // 'All', 'Expired', 'Expiring Soon'

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(complianceAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet & Driver Compliance'),
        backgroundColor: AppColors.managerAccent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(complianceAlertsProvider),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // Filter chips header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Documents'),
                      selected: _filter == 'All',
                      onSelected: (_) => setState(() => _filter = 'All'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Expired (Blocks Trips)'),
                      selected: _filter == 'Expired',
                      selectedColor: Colors.red.shade100,
                      onSelected: (_) => setState(() => _filter = 'Expired'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Expiring Soon (< 30 days)'),
                      selected: _filter == 'Expiring Soon',
                      selectedColor: Colors.amber.shade100,
                      onSelected: (_) => setState(() => _filter = 'Expiring Soon'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: alertsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading compliance alerts: $e')),
                  data: (alerts) {
                    final filtered = alerts.where((a) {
                      if (_filter == 'Expired') return a.isExpired;
                      if (_filter == 'Expiring Soon') return a.isExpiringSoon;
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 56, color: AppColors.statusGood),
                            const SizedBox(height: 12),
                            const Text('All fleet and driver documents are compliant!', style: AppTypography.heading),
                            const SizedBox(height: 4),
                            Text('No documents are expired or expiring soon.', style: AppTypography.caption.copyWith(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final alert = filtered[index];
                        final isExpired = alert.isExpired;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      alert.documentType.isDriverDoc ? Icons.badge : Icons.directions_bus,
                                      color: isExpired ? AppColors.statusCritical : AppColors.statusWarning,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alert.documentType.label,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            alert.entityName,
                                            style: AppTypography.bodySmall.copyWith(color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isExpired ? Colors.red.shade50 : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isExpired ? Colors.red.shade300 : Colors.amber.shade400,
                                        ),
                                      ),
                                      child: Text(
                                        isExpired ? 'EXPIRED (BLOCKED)' : 'EXPIRING SOON',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isExpired ? Colors.red.shade900 : Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('Document No: ${alert.documentNumber}', style: AppTypography.caption),
                                    ),
                                    Text(
                                      isExpired
                                          ? 'Expired ${alert.daysUntilExpiry.abs()} days ago'
                                          : 'Expires in ${alert.daysUntilExpiry} days',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isExpired ? AppColors.statusCritical : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isExpired
                                      ? '⚠ Drivers scanning this bus will be blocked with a pop-up warning.'
                                      : 'ℹ Advisory pop-up is shown to driver upon scan; operation permitted.',
                                  style: AppTypography.caption.copyWith(
                                    color: isExpired ? Colors.red.shade800 : Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
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
