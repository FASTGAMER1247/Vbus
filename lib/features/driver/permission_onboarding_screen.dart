import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import 'driver_providers.dart';

/// flow.md D1 — screen DR-2. design.md §7.3 "Permission prompt screen:
/// explains why it is needed before the system prompt." Reached only
/// on a driver's first trip (prd.md rule: background location asked
/// only from drivers, only when starting a trip).
class PermissionOnboardingScreen extends ConsumerStatefulWidget {
  const PermissionOnboardingScreen({super.key});

  @override
  ConsumerState<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends ConsumerState<PermissionOnboardingScreen> {
  bool _isRequesting = false;
  bool _wasDenied = false;

  Future<void> _grant() async {
    setState(() => _isRequesting = true);
    final granted = await ref.read(driverFlowProvider.notifier).requestPermissions();
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _wasDenied = !granted;
    });
    if (granted) context.push('/driver/identify');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.driverAccent, title: const Text('Location access')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_on_outlined, size: 56),
            const SizedBox(height: 16),
            const Text('This app needs your location while you drive', style: AppTypography.heading),
            const SizedBox(height: 12),
            const Text(
              'So students and your manager can see the bus live. Location is shared only while a trip is '
              'active, and only your manager and your route\'s students can see it.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'ll be asked to allow location "All the time" so tracking keeps working with the screen '
              'locked. This is only ever asked of drivers, and only when starting a trip.',
              style: AppTypography.bodySmall,
            ),
            if (_wasDenied) ...[
              const SizedBox(height: 16),
              Text(
                'Location access is needed to start a trip. Please enable it in your phone settings and try again.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.statusCritical),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: const Text('Open settings'),
              ),
            ],
            const Spacer(),
            PrimaryButton(
              label: 'Allow location access',
              accentColor: AppColors.driverAccent,
              isLoading: _isRequesting,
              onPressed: _grant,
            ),
          ],
        ),
      ),
    );
  }
}
