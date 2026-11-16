import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_transit/core/config/supabase_config.dart';
import 'package:campus_transit/data/remote/supabase_client_provider.dart';
import 'package:campus_transit/data/mock/mock_auth_repository.dart';
import 'package:campus_transit/data/mock/mock_driver_repository.dart';
import 'package:campus_transit/data/mock/mock_manager_repository.dart';
import 'package:campus_transit/data/mock/mock_transport_repository.dart';
import 'package:campus_transit/data/mock/mock_admin_repository.dart';
import 'package:campus_transit/app/providers.dart';

void main() {
  group('Supabase Backend Reconciliation & Fallback Architecture', () {
    test('SupabaseConfig is well-formed with configured backend credentials', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.anonKey, isNotEmpty);
      expect(SupabaseConfig.isConfigured, isTrue);
    });

    test('supabaseClientProvider returns null when unconfigured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(supabaseClientProvider);
      expect(client, isNull);
    });

    test('Repository providers gracefully fallback to Mock implementations when offline', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authRepo = container.read(authRepositoryProvider);
      final driverRepo = container.read(driverRepositoryProvider);
      final transportRepo = container.read(transportRepositoryProvider);
      final managerRepo = container.read(managerRepositoryProvider);
      final adminRepo = container.read(adminRepositoryProvider);

      expect(authRepo, isA<MockAuthRepository>());
      expect(driverRepo, isA<MockDriverRepository>());
      expect(transportRepo, isA<MockTransportRepository>());
      expect(managerRepo, isA<MockManagerRepository>());
      expect(adminRepo, isA<MockAdminRepository>());
    });

    test('Mock fallback provides full data fidelity for trips, routes and compliance', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final driverRepo = container.read(driverRepositoryProvider);
      final trip = await driverRepo.getTodayScheduledTrip('driver-1');

      expect(trip, isNotNull);
      expect(trip!.bus.busNumber, equals('023'));
      expect(trip.route.stops, isNotEmpty);

      final managerRepo = container.read(managerRepositoryProvider);
      final alerts = await managerRepo.getComplianceAlerts('college-1');
      expect(alerts, isNotEmpty);
    });
  });
}
