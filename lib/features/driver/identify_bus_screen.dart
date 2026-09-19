import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import 'driver_providers.dart';

/// flow.md D1 "Identify the bus" step. Combines DR-3 (scan) and DR-4
/// (manual) as two tabs, matching design.md §7.4's "Bus QR scanner
/// view ... with an 'Enter Bus ID instead' option."
///
/// Backend note (BACKEND_CHANGES.md #6): there's no bus-lookup RPC
/// yet, so a real scan can't resolve to a trip today. The camera/scan
/// UI is still built and wired to DriverFlowController.identifyBus —
/// swapping in the real lookup later is a repository-layer change,
/// not a screen change.
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

  Future<void> _submit(String code) async {
    final ok = await ref.read(driverFlowProvider.notifier).identifyBus(code);
    if (!mounted) return;

    if (ok) {
      context.push('/driver/confirm');
    } else {
      final reason = ref.read(driverFlowProvider).blockReason;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason?.message ?? 'Something went wrong.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(driverFlowProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.driverAccent,
        title: const Text('Identify bus'),
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
          // DR-3
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
              // Framing guide
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => _tabController.animateTo(1),
                    child: const Text('Enter Bus ID instead', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              if (flow.isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
          // DR-4
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter the Bus ID printed on the vehicle', style: AppTypography.body),
                const SizedBox(height: 16),
                TextField(
                  controller: _busIdController,
                  decoration: const InputDecoration(
                    labelText: 'Bus ID',
                    hintText: 'e.g. 023',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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
