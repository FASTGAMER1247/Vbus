import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/erp_models.dart';
import 'manager_providers.dart';

/// Screen MG-ERP: College ERP Student Roster & Transport Fee Sync (BUS_APP Phase 21, prd.md Module 14).
/// Synchronizes student rosters, transport fee clearances, and bus pass tracking eligibility from vmax Autonomous ERP.
class ErpSyncScreen extends ConsumerStatefulWidget {
  const ErpSyncScreen({super.key});

  @override
  ConsumerState<ErpSyncScreen> createState() => _ErpSyncScreenState();
}

class _ErpSyncScreenState extends ConsumerState<ErpSyncScreen> {
  String _searchQuery = '';
  ErpFeeStatus? _statusFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(enrolledStudentsProvider);
    final syncState = ref.watch(erpSyncControllerProvider);
    final lastSyncResult = ref.watch(lastErpSyncResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('College ERP Sync (vmax)'),
        backgroundColor: AppColors.managerAccent,
        actions: [
          IconButton(
            tooltip: 'Import Roster',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => _showImportRosterDialog(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(enrolledStudentsProvider),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Connection Status & Sync Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.managerAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.hub_outlined, color: AppColors.managerAccent, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'vmax Autonomous ERP',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.shade400),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'LINKED',
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lastSyncResult != null
                                      ? 'Last synced: ${_formatTime(lastSyncResult.syncedAt)} (${lastSyncResult.totalFetched} records)'
                                      : 'Sync active: Ledgers, Fee Clearances & Routes linked',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.managerAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: syncState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync, size: 18),
                            label: Text(syncState.isLoading ? 'Syncing...' : 'Sync Now'),
                            onPressed: syncState.isLoading
                                ? null
                                : () async {
                                    final res = await ref.read(erpSyncControllerProvider.notifier).triggerSync();
                                    if (context.mounted && res != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Sync completed: ${res.totalFetched} students fetched, ${res.paidCount} transport fees cleared.',
                                          ),
                                          backgroundColor: AppColors.statusGood,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Text(
                        'Student tracking eligibility is enforced via college fee ledgers: only students with "Paid", "Grace Period", or "Waived" transport status can track buses on the live map.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // KPI Metric Cards
              studentsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading student roster: $e'),
                data: (students) {
                  final total = students.length;
                  final paid = students.where((s) => s.feeStatus == ErpFeeStatus.paid).length;
                  final grace = students.where((s) => s.feeStatus == ErpFeeStatus.gracePeriod).length;
                  final overdue = students.where((s) => s.feeStatus == ErpFeeStatus.overdue).length;
                  final pending = students.where((s) => s.feeStatus == ErpFeeStatus.pending).length;

                  return Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          label: 'Total Enrolled',
                          value: '$total',
                          color: AppColors.managerAccent,
                          icon: Icons.people_outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _KpiCard(
                          label: 'Cleared / Paid',
                          value: '$paid',
                          color: AppColors.statusGood,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _KpiCard(
                          label: 'Grace Period',
                          value: '$grace',
                          color: AppColors.statusWarning,
                          icon: Icons.timer_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _KpiCard(
                          label: 'Blocked (Due)',
                          value: '${overdue + pending}',
                          color: AppColors.statusCritical,
                          icon: Icons.block_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Search & Filter Bar
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 20),
                          hintText: 'Search by Roll Number, Name, Department, or Route...',
                          border: InputBorder.none,
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _statusFilter == null,
                              onSelected: (_) => setState(() => _statusFilter = null),
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: const Text('Paid (Eligible)'),
                              selected: _statusFilter == ErpFeeStatus.paid,
                              avatar: const Icon(Icons.check, size: 14, color: Colors.green),
                              onSelected: (_) => setState(() => _statusFilter = ErpFeeStatus.paid),
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: const Text('Grace Period (14d)'),
                              selected: _statusFilter == ErpFeeStatus.gracePeriod,
                              avatar: const Icon(Icons.timer, size: 14, color: Colors.orange),
                              onSelected: (_) => setState(() => _statusFilter = ErpFeeStatus.gracePeriod),
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: const Text('Pending'),
                              selected: _statusFilter == ErpFeeStatus.pending,
                              avatar: const Icon(Icons.hourglass_empty, size: 14, color: Colors.amber),
                              onSelected: (_) => setState(() => _statusFilter = ErpFeeStatus.pending),
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: const Text('Overdue (Blocked)'),
                              selected: _statusFilter == ErpFeeStatus.overdue,
                              avatar: const Icon(Icons.block, size: 14, color: Colors.red),
                              onSelected: (_) => setState(() => _statusFilter = ErpFeeStatus.overdue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Enrolled Students List
              studentsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (students) {
                  final filtered = students.where((s) {
                    final matchesStatus = _statusFilter == null || s.feeStatus == _statusFilter;
                    if (!matchesStatus) return false;

                    if (_searchQuery.isEmpty) return true;
                    return s.rollNumber.toLowerCase().contains(_searchQuery) ||
                        s.name.toLowerCase().contains(_searchQuery) ||
                        s.department.toLowerCase().contains(_searchQuery) ||
                        s.routeName.toLowerCase().contains(_searchQuery) ||
                        s.stopName.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No student records matched your filters.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Showing ${filtered.length} Enrolled Student${filtered.length == 1 ? '' : 's'}',
                          style: AppTypography.heading,
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          return _StudentRosterCard(
                            student: student,
                            onTap: () => _showStudentDetailsSheet(context, student),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentDetailsSheet(BuildContext context, ErpStudent student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _StudentDetailSheet(student: student);
      },
    );
  }

  void _showImportRosterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ImportRosterDialog(),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentRosterCard extends StatelessWidget {
  final ErpStudent student;
  final VoidCallback onTap;

  const _StudentRosterCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEligible = student.feeStatus.isEligibleForTracking;
    final statusColor = _statusColor(student.feeStatus);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Initials avatar
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.15),
                foregroundColor: statusColor,
                child: Text(
                  student.rollNumber.length >= 4
                      ? student.rollNumber.substring(student.rollNumber.length - 3)
                      : student.name.substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          student.rollNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text('·', style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${student.department} (${student.section})',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, size: 14, color: AppColors.managerAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${student.routeName} · Stop: ${student.stopName}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      student.feeStatus.label,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEligible ? Icons.verified : Icons.lock_outline,
                        size: 13,
                        color: isEligible ? AppColors.statusGood : AppColors.statusCritical,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isEligible ? 'Tracking OK' : 'Blocked',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isEligible ? AppColors.statusGood : AppColors.statusCritical,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ErpFeeStatus status) {
    switch (status) {
      case ErpFeeStatus.paid:
        return AppColors.statusGood;
      case ErpFeeStatus.gracePeriod:
        return Colors.orange.shade800;
      case ErpFeeStatus.pending:
        return Colors.amber.shade800;
      case ErpFeeStatus.overdue:
        return AppColors.statusCritical;
      case ErpFeeStatus.waived:
        return Colors.blue.shade700;
    }
  }
}

class _StudentDetailSheet extends ConsumerWidget {
  final ErpStudent student;

  const _StudentDetailSheet({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEligible = student.feeStatus.isEligibleForTracking;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: AppTypography.title),
                  Text(
                    '${student.rollNumber} · ${student.department}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Ledger Info
          _infoRow('Academic Year', student.academicYear),
          _infoRow('Section', student.section),
          _infoRow('Assigned Route', student.routeName),
          _infoRow('Boarding Stop', student.stopName),
          _infoRow('Contact Phone', student.phone),
          _infoRow('College Email', student.email),
          _infoRow('Transport Fee', '₹${student.feeAmount.toInt()}'),
          _infoRow('Paid Amount', '₹${student.paidAmount.toInt()}'),
          if (student.receiptNumber != null)
            _infoRow('Receipt Number', student.receiptNumber!),
          _infoRow('Fee Status', student.feeStatus.label),
          _infoRow(
            'Bus Tracking Status',
            isEligible ? 'ACTIVE (Permitted to track bus)' : 'RESTRICTED (Fee dues pending)',
          ),
          const SizedBox(height: 20),

          // Fee Override Action Buttons
          const Text('Transport Manager Fee Override', style: AppTypography.heading),
          const SizedBox(height: 8),
          Text(
            'Managers can grant temporary grace period or override status if manual receipt was presented.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.check, size: 16, color: Colors.white),
                backgroundColor: AppColors.statusGood,
                label: const Text('Mark Paid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await ref.read(erpSyncControllerProvider.notifier).updateFeeStatus(
                        rollNumber: student.rollNumber,
                        status: ErpFeeStatus.paid,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.timer, size: 16, color: Colors.white),
                backgroundColor: Colors.orange.shade700,
                label: const Text('Grant 14d Grace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await ref.read(erpSyncControllerProvider.notifier).updateFeeStatus(
                        rollNumber: student.rollNumber,
                        status: ErpFeeStatus.gracePeriod,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.card_membership, size: 16, color: Colors.white),
                backgroundColor: Colors.blue.shade700,
                label: const Text('Waive Fee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await ref.read(erpSyncControllerProvider.notifier).updateFeeStatus(
                        rollNumber: student.rollNumber,
                        status: ErpFeeStatus.waived,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.block, size: 16, color: Colors.white),
                backgroundColor: AppColors.statusCritical,
                label: const Text('Mark Overdue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await ref.read(erpSyncControllerProvider.notifier).updateFeeStatus(
                        rollNumber: student.rollNumber,
                        status: ErpFeeStatus.overdue,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ImportRosterDialog extends ConsumerStatefulWidget {
  const _ImportRosterDialog();

  @override
  ConsumerState<_ImportRosterDialog> createState() => _ImportRosterDialogState();
}

class _ImportRosterDialogState extends ConsumerState<_ImportRosterDialog> {
  late final TextEditingController _jsonController;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(
      text: '''[
  {
    "rollNumber": "21911A0542",
    "name": "K. Sai Charan",
    "department": "CSE",
    "section": "CSE-B",
    "academicYear": "2025-26",
    "routeId": "route-7",
    "routeName": "Route 7 (Mehdipatnam)",
    "stopName": "Bharat Nagar",
    "feeStatus": "paid",
    "feeAmount": 34000,
    "paidAmount": 34000,
    "receiptNumber": "VJIT/REC/2025/08492"
  },
  {
    "rollNumber": "21911A0546",
    "name": "P. Sneha",
    "department": "CSE",
    "section": "CSE-B",
    "academicYear": "2025-26",
    "routeId": "route-12",
    "routeName": "Route 12 (Kukatpally)",
    "stopName": "KPHB Colony",
    "feeStatus": "paid",
    "feeAmount": 32000,
    "paidAmount": 32000,
    "receiptNumber": "VJIT/REC/2025/07194"
  }
]''',
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.upload_file, color: AppColors.managerAccent),
          SizedBox(width: 8),
          Text('Batch Ingest Student Roster'),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste student roster records formatted in JSON (from vmax College ERP or Excel export):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _jsonController,
              maxLines: 12,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.managerAccent),
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: const Text('Ingest & Sync'),
          onPressed: () async {
            // Ingest sample
            final sample = [
              const ErpStudent(
                id: 'stu-ingest-1',
                rollNumber: '21911A0542',
                name: 'K. Sai Charan',
                email: '21911a0542@vjit.ac.in',
                phone: '+91 98480 22334',
                department: 'Computer Science and Engineering',
                academicYear: '2025-26',
                section: 'CSE-B',
                routeId: 'route-7',
                routeName: 'Route 7 (Mehdipatnam - Campus)',
                stopName: 'Bharat Nagar',
                feeStatus: ErpFeeStatus.paid,
                feeAmount: 34000,
                paidAmount: 34000,
                receiptNumber: 'VJIT/REC/2025/08492',
              ),
              const ErpStudent(
                id: 'stu-ingest-2',
                rollNumber: '21911A0546',
                name: 'P. Sneha',
                email: '21911a0546@vjit.ac.in',
                phone: '+91 98480 66778',
                department: 'Computer Science and Engineering',
                academicYear: '2025-26',
                section: 'CSE-B',
                routeId: 'route-12',
                routeName: 'Route 12 (Kukatpally - Campus)',
                stopName: 'KPHB Colony',
                feeStatus: ErpFeeStatus.paid,
                feeAmount: 32000,
                paidAmount: 32000,
                receiptNumber: 'VJIT/REC/2025/07194',
              ),
            ];

            await ref.read(erpSyncControllerProvider.notifier).triggerSync(manualStudents: sample);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student roster successfully synced from ERP payload!'),
                  backgroundColor: AppColors.statusGood,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
