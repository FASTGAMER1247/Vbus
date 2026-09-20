import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/transport_models.dart';
import '../../core/widgets/primary_button.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 1 — Add Bus Form (Screen MG-3).
class BusFormScreen extends ConsumerStatefulWidget {
  const BusFormScreen({super.key});

  @override
  ConsumerState<BusFormScreen> createState() => _BusFormScreenState();
}

class _BusFormScreenState extends ConsumerState<BusFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _capacityController = TextEditingController(text: '40');
  bool _isLoading = false;

  @override
  void dispose() {
    _busNumberController.dispose();
    _regNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = ref.read(authControllerProvider);
    final collegeId = user?.collegeId ?? 'college-vjit';

    final bus = Bus(
      id: 'bus-${_busNumberController.text.trim()}',
      busNumber: _busNumberController.text.trim(),
      registrationNumber: _regNumberController.text.trim(),
      capacity: int.tryParse(_capacityController.text.trim()) ?? 40,
    );

    await ref.read(managerRepositoryProvider).saveBus(collegeId: collegeId, bus: bus);
    ref.invalidate(busesProvider);
    ref.invalidate(fleetSummaryProvider);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bus'),
        backgroundColor: AppColors.managerAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text('Vehicle Profile', style: AppTypography.heading),
                  const SizedBox(height: 8),
                  const Text('Register a new bus to your college fleet.', style: AppTypography.bodySmall),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _busNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Bus Number / ID *',
                      hintText: 'e.g. 023 or Bus-7',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a bus number' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _regNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number *',
                      hintText: 'e.g. TS 09 AB 1234',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter vehicle registration' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Seating Capacity',
                      hintText: 'e.g. 40',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Enter a valid seating capacity';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Save Bus',
                    accentColor: AppColors.managerAccent,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
