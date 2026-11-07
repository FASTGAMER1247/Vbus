import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import 'admin_providers.dart';

/// flow.md A2, MA-5 — Provision transport manager account for a college.
class AdminManagerFormScreen extends ConsumerStatefulWidget {
  final String? initialCollegeId;

  const AdminManagerFormScreen({super.key, this.initialCollegeId});

  @override
  ConsumerState<AdminManagerFormScreen> createState() => _AdminManagerFormScreenState();
}

class _AdminManagerFormScreenState extends ConsumerState<AdminManagerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Transit@Manager2026');

  String? _selectedCollegeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCollegeId = widget.initialCollegeId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%*';
    final random = Random.secure();
    final pass = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() => _passwordController.text = pass);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a college for this manager.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(adminRepositoryProvider).createManager(
            collegeId: _selectedCollegeId!,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
          );

      ref.invalidate(adminManagersProvider(_selectedCollegeId));
      ref.invalidate(adminManagersProvider(null));
      ref.invalidate(platformSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manager ${_nameController.text.trim()} provisioned successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error provisioning manager: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collegesAsync = ref.watch(collegesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provision Transport Manager'),
        backgroundColor: AppColors.masterAdminAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manager Identity & Assignment', style: AppTypography.heading),
                  const SizedBox(height: 6),
                  const Text(
                    'Create manager credentials. The manager can immediately log in to setup and run trips.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  collegesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading colleges: $e'),
                    data: (colleges) {
                      _selectedCollegeId ??= colleges.isNotEmpty ? colleges.first.id : null;
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCollegeId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned College *',
                          border: OutlineInputBorder(),
                        ),
                        items: colleges.map((college) {
                          return DropdownMenuItem(
                            value: college.id,
                            child: Text('${college.collegeName} (${college.collegeCode})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCollegeId = val),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Ramesh Kumar',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'e.g. ramesh@college.edu',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || !val.contains('@') ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: '+91 98480 12345',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Temporary Password *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Generate Random Password',
                        onPressed: _generatePassword,
                      ),
                    ),
                    validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 28),

                  PrimaryButton(
                    label: 'Provision Manager Account',
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
