import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/admin_models.dart';
import '../../core/widgets/primary_button.dart';
import 'admin_providers.dart';

/// flow.md A1, MA-3 — Onboard / Edit College profile and geofence settings.
class CollegeFormScreen extends ConsumerStatefulWidget {
  final String? collegeId;

  const CollegeFormScreen({super.key, this.collegeId});

  @override
  ConsumerState<CollegeFormScreen> createState() => _CollegeFormScreenState();
}

class _CollegeFormScreenState extends ConsumerState<CollegeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _domainController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'Telangana');
  final _latController = TextEditingController(text: '17.3605');
  final _lngController = TextEditingController(text: '78.3615');

  double _radiusMeters = 250.0;
  TransportFeePolicy _feePolicy = TransportFeePolicy.warningOnly;
  CollegeStatus _status = CollegeStatus.active;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.collegeId != null) {
      _loadExistingCollege();
    }
  }

  Future<void> _loadExistingCollege() async {
    _initialized = true;
    final college = await ref.read(adminRepositoryProvider).getCollegeById(widget.collegeId!);
    if (college != null && mounted) {
      setState(() {
        _codeController.text = college.collegeCode;
        _nameController.text = college.collegeName;
        _domainController.text = college.emailDomain ?? '';
        _phoneController.text = college.phone;
        _emailController.text = college.email;
        _cityController.text = college.city;
        _stateController.text = college.state;
        _latController.text = college.campusLatitude.toString();
        _lngController.text = college.campusLongitude.toString();
        _radiusMeters = college.campusRadiusMeters;
        _feePolicy = college.feePolicy;
        _status = college.status;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _domainController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.collegeId != null;
      final collegeId = widget.collegeId ?? 'college-${_codeController.text.trim().toLowerCase()}';

      final college = College(
        id: collegeId,
        collegeCode: _codeController.text.trim().toUpperCase(),
        collegeName: _nameController.text.trim(),
        emailDomain: _domainController.text.trim().isEmpty ? null : _domainController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        campusLatitude: double.parse(_latController.text.trim()),
        campusLongitude: double.parse(_lngController.text.trim()),
        campusRadiusMeters: _radiusMeters,
        status: _status,
        feePolicy: _feePolicy,
        createdAt: DateTime.now(),
      );

      await ref.read(adminRepositoryProvider).saveCollege(college);
      ref.invalidate(collegesProvider);
      ref.invalidate(platformSummaryProvider);
      if (isEdit) {
        ref.invalidate(collegeDetailProvider(collegeId));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'College updated successfully!' : 'College onboarded successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save college: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.collegeId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit College Settings' : 'Onboard New College'),
        backgroundColor: AppColors.masterAdminAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('General Information', style: AppTypography.heading),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'College Code *',
                            hintText: 'e.g. VJIT',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full College Name *',
                            hintText: 'e.g. Vidya Jyothi Institute of Technology',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _domainController,
                          decoration: const InputDecoration(
                            labelText: 'Email Domain',
                            hintText: 'e.g. vjit.ac.in',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Official Email *',
                            hintText: 'transport@vjit.ac.in',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || !val.contains('@') ? 'Valid email required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Phone *',
                            hintText: '+91 8413 235300',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            hintText: 'Hyderabad',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            hintText: 'Telangana',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Campus Geofence Configuration (flow.md A1, prd.md Module 2 & 21)
                  const Text('Campus Geofence Configuration', style: AppTypography.heading),
                  const SizedBox(height: 6),
                  const Text(
                    'Essential for automatic trip completion and campus arrival alerts.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Campus Latitude *',
                            hintText: '17.3605',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            final n = double.tryParse(val ?? '');
                            if (n == null || n < -90 || n > 90) return 'Invalid latitude (-90 to 90)';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Campus Longitude *',
                            hintText: '78.3615',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            final n = double.tryParse(val ?? '');
                            if (n == null || n < -180 || n > 180) return 'Invalid longitude (-180 to 180)';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Card(
                    elevation: 0,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Geofence Radius', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${_radiusMeters.toInt()} meters',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.masterAdminAccent),
                              ),
                            ],
                          ),
                          Slider(
                            value: _radiusMeters,
                            min: 50.0,
                            max: 1500.0,
                            divisions: 29,
                            activeColor: AppColors.masterAdminAccent,
                            label: '${_radiusMeters.toInt()}m',
                            onChanged: (val) => setState(() => _radiusMeters = val),
                          ),
                          const Text(
                            'Buses that enter this radius will trigger the "College Geofence" stage and automatic trip completion.',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Policies & Status
                  const Text('Governance & Policy Settings', style: AppTypography.heading),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TransportFeePolicy>(
                    initialValue: _feePolicy,
                    decoration: const InputDecoration(
                      labelText: 'Transport-Fee Policy (flow.md A1)',
                      border: OutlineInputBorder(),
                    ),
                    items: TransportFeePolicy.values.map((policy) {
                      return DropdownMenuItem(
                        value: policy,
                        child: Text(policy.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _feePolicy = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  if (isEdit)
                    DropdownButtonFormField<CollegeStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'College Operational Status (flow.md A3)',
                        border: OutlineInputBorder(),
                      ),
                      items: CollegeStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  const SizedBox(height: 28),

                  PrimaryButton(
                    label: isEdit ? 'Save Changes' : 'Onboard College',
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
