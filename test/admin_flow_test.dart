import 'package:flutter_test/flutter_test.dart';
import 'package:campus_transit/core/models/admin_models.dart';
import 'package:campus_transit/data/mock/mock_admin_repository.dart';

void main() {
  group('Master Admin Flow & Repository Tests (flow.md A1–A3)', () {
    late MockAdminRepository repo;

    setUp(() {
      repo = MockAdminRepository();
    });

    test('getPlatformSummary returns aggregate metrics across colleges', () async {
      final summary = await repo.getPlatformSummary();
      expect(summary.totalColleges, greaterThan(0));
      expect(summary.totalManagers, greaterThan(0));
      expect(summary.activeColleges, greaterThanOrEqualTo(0));
      expect(summary.totalBuses, greaterThan(0));
    });

    test('A1: create and retrieve a new college with geofence settings', () async {
      final newCollege = College(
        id: 'college-test',
        collegeCode: 'TEST',
        collegeName: 'Test Institute of Technology',
        phone: '+91 99999 88888',
        email: 'admin@test.edu',
        city: 'Hyderabad',
        state: 'Telangana',
        campusLatitude: 17.4000,
        campusLongitude: 78.4000,
        campusRadiusMeters: 350.0,
        status: CollegeStatus.active,
        feePolicy: TransportFeePolicy.strictBlocking,
        createdAt: DateTime.now(),
      );

      await repo.saveCollege(newCollege);

      final retrieved = await repo.getCollegeById('college-test');
      expect(retrieved, isNotNull);
      expect(retrieved!.collegeCode, 'TEST');
      expect(retrieved.campusRadiusMeters, 350.0);
      expect(retrieved.feePolicy, TransportFeePolicy.strictBlocking);
      expect(retrieved.status, CollegeStatus.active);
    });

    test('A3: toggle college status between active, deactivated, and archived', () async {
      await repo.setCollegeStatus('college-vjit', CollegeStatus.deactivated);
      var vjit = await repo.getCollegeById('college-vjit');
      expect(vjit!.status, CollegeStatus.deactivated);
      expect(vjit.isActive, isFalse);

      await repo.setCollegeStatus('college-vjit', CollegeStatus.archived);
      vjit = await repo.getCollegeById('college-vjit');
      expect(vjit!.status, CollegeStatus.archived);

      await repo.setCollegeStatus('college-vjit', CollegeStatus.active);
      vjit = await repo.getCollegeById('college-vjit');
      expect(vjit!.status, CollegeStatus.active);
      expect(vjit.isActive, isTrue);
    });

    test('A2: create transport manager and toggle access', () async {
      final manager = await repo.createManager(
        collegeId: 'college-vjit',
        name: 'New Test Manager',
        email: 'test.manager@vjit.ac.in',
        phone: '+91 91234 56789',
        password: 'SecurePassword123!',
      );

      expect(manager.id, isNotEmpty);
      expect(manager.name, 'New Test Manager');
      expect(manager.isActive, isTrue);

      final collegeManagers = await repo.getManagers(collegeId: 'college-vjit');
      expect(collegeManagers.any((m) => m.id == manager.id), isTrue);

      await repo.toggleManagerStatus(managerId: manager.id, isActive: false);
      final updatedList = await repo.getManagers(collegeId: 'college-vjit');
      final updatedManager = updatedList.firstWhere((m) => m.id == manager.id);
      expect(updatedManager.isActive, isFalse);
    });
  });
}
