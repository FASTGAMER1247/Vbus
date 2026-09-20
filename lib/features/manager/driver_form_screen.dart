import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/transport_models.dart';
import '../../core/widgets/primary_button.dart';
import 'manager_providers.dart';

/// flow.md M1 Step 2 — Add Driver Form (Screen MG-5).
class DriverFormScreen extends ConsumerStatefulWidget {
  const DriverFormScreen({super.key});

  @override
  ConsumerState<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends ConsumerState<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = ref.read(authControllerProvider);
    final collegeId = user?.collegeId ?? 'college-vjit';

    final driver = DriverProfile(
      id: 'driver-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    await ref.read(managerRepositoryProvider).saveDriver(collegeId: collegeId, driver: driver);
    ref.invalidate(driversProvider);
    ref.invalidate(fleetSummaryProvider);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Driver'),
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
                  const Text('Driver Profile', style: AppTypography.heading),
                  const SizedBox(height: 8),
                  const Text('Register a driver to operate college buses.', style: AppTypography.bodySmall),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Ramesh Kumar',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: 'e.g. +91 98765 43210',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a phone number' : null,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Save Driver',
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
