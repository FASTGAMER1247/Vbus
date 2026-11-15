import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/compliance_models.dart';
import '../../core/widgets/primary_button.dart';
import 'driver_providers.dart';

/// flow.md D1 "Identify the bus" step (Screens DR-3 and DR-4).
/// Supports camera QR scanning, manual Bus ID, unassigned driver takeover,
/// and document compliance expiry pop-ups.
class IdentifyBusScreen extends ConsumerStatefulWidget {
  const IdentifyBusScreen({super.key});

  @override
  ConsumerState<IdentifyBusScreen> createState() => _IdentifyBusScreenState();
}

class _IdentifyBusScreenState extends ConsumerState<IdentifyBusScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _busIdController = TextEditingController();
  bool _scannedOnce = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busIdController.dispose();
    super.dispose();
  }

  Future<void> _submit(String code) async {
    final result = await ref.read(driverFlowProvider.notifier).identifyBus(code);
    if (!mounted) return;

    if (result != null) {
      // Check if there is an advisory alert (e.g. expiring soon within 30 days)
      if (result.advisoryAlert != null) {
        final proceed = await _showAdvisoryDialog(context, result.advisoryAlert!);
        if (!proceed || !mounted) return;
      } else if (result.isUnassignedTakeover) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.driverAccent,
            content: Text(
              'Unassigned Driver: Authorized to operate Bus ${result.trip.bus.busNumber} for today.',
            ),
          ),
        );
      }

      context.push('/driver/confirm');
    } else {
      final state = ref.read(driverFlowProvider);
      if (state.blockedDocumentAlert != null) {
        // Document Expiry Pop-up modal!
        await _showDocumentBlockedDialog(context, state.blockedDocumentAlert!);
      } else {
        final reason = state.blockReason;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason?.message ?? 'Something went wrong.')),
        );
      }
    }
  }

  /// Pop-up modal when trip is blocked due to expired license or bus document.
  Future<void> _showDocumentBlockedDialog(BuildContext context, DocumentAlert alert) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          icon: const Icon(Icons.gpp_bad, color: AppColors.statusCritical, size: 48),
          title: const Text(
            'Operation Blocked: Expired Document',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety & Legal Compliance Policy Enforced',
                style: AppTypography.caption.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.documentType.label,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusCritical),
                    ),
                    const SizedBox(height: 4),
                    Text('Entity: ${alert.entityName}', style: AppTypography.bodySmall),
                    Text('Document No: ${alert.documentNumber}', style: AppTypography.bodySmall),
                    Text(
                      'Expired: ${alert.expiryDate.year}-${alert.expiryDate.month.toString().padLeft(2, '0')}-${alert.expiryDate.day.toString().padLeft(2, '0')} (${alert.daysUntilExpiry.abs()} days ago)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.statusCritical),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'This trip cannot be started until this document is renewed. An alert has been dispatched to the Transport Manager CRM.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.statusCritical),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  /// Advisory pop-up modal when document is expiring soon (non-blocking).
  Future<bool> _showAdvisoryDialog(BuildContext context, DocumentAlert alert) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.statusWarning, size: 44),
          title: const Text(
            'Compliance Advisory: Expiring Soon',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.documentType.label,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                    const SizedBox(height: 4),
                    Text('Entity: ${alert.entityName}', style: AppTypography.bodySmall),
                    Text('Document No: ${alert.documentNumber}', style: AppTypography.bodySmall),
                    Text(
                      'Expires in ${alert.daysUntilExpiry} days (${alert.expiryDate.year}-${alert.expiryDate.month.toString().padLeft(2, '0')}-${alert.expiryDate.day.toString().padLeft(2, '0')})',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You may proceed with today\'s trip. Please inform your transport manager to renew this document before expiry.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.driverAccent),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Proceed to Trip'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(driverFlowProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.driverAccent,
        title: const Text('Identify Bus'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Enter Bus ID'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // DR-3: Camera QR Scanner
          Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                onDetect: (capture) {
                  if (_scannedOnce || flow.isLoading) return;
                  final code =
                      capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                  if (code != null) {
                    setState(() => _scannedOnce = true);
                    _submit(code).whenComplete(() => setState(() => _scannedOnce = false));
                  }
                },
              ),
              // Camera framing guide
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Align QR code within frame',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(backgroundColor: Colors.black87),
                    icon: const Icon(Icons.keyboard, color: Colors.white),
                    label: const Text('Enter Bus ID instead', style: TextStyle(color: Colors.white)),
                    onPressed: () => _tabController.animateTo(1),
                  ),
                ),
              ),
              if (flow.isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
          // DR-4: Manual ID entry
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter the Bus ID printed on the vehicle dashboard', style: AppTypography.body),
                const SizedBox(height: 16),
                TextField(
                  controller: _busIdController,
                  decoration: const InputDecoration(
                    labelText: 'Bus ID',
                    hintText: 'e.g. 023, 015, 009, 042',
                    prefixIcon: Icon(Icons.directions_bus),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Demo IDs: "023" (Assigned), "015" (Unassigned Takeover), "009" (Expiring PUC), "042" (Expired Insurance)',
                  style: AppTypography.caption.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Continue',
                  accentColor: AppColors.driverAccent,
                  isLoading: flow.isLoading,
                  onPressed: () => _submit(_busIdController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
