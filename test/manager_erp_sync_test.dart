import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_transit/core/models/erp_models.dart';
import 'package:campus_transit/data/mock/mock_manager_repository.dart';
import 'package:campus_transit/features/manager/manager_providers.dart';
import 'package:campus_transit/app/providers.dart';

void main() {
  group('College ERP Student Roster & Fee Sync (vmax ERP)', () {
    late MockManagerRepository mockManagerRepo;
    late ProviderContainer container;

    setUp(() {
      mockManagerRepo = MockManagerRepository();
      container = ProviderContainer(
        overrides: [
          managerRepositoryProvider.overrideWithValue(mockManagerRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('getEnrolledStudents retrieves students with vmax ERP fields and fee status', () async {
      final students = await mockManagerRepo.getEnrolledStudents('college-vjit');

      expect(students, isNotEmpty);
      final saiCharan = students.firstWhere((s) => s.rollNumber == '21911A0542');
      expect(saiCharan.name, equals('K. Sai Charan'));
      expect(saiCharan.department, equals('Computer Science and Engineering'));
      expect(saiCharan.section, equals('CSE-B'));
      expect(saiCharan.feeStatus, equals(ErpFeeStatus.paid));
      expect(saiCharan.feeAmount, equals(34000.0));
      expect(saiCharan.paidAmount, equals(34000.0));
      expect(saiCharan.feeStatus.isEligibleForTracking, isTrue);
    });

    test('Fee status eligibility rules correctly gate live bus tracking access', () {
      expect(ErpFeeStatus.paid.isEligibleForTracking, isTrue);
      expect(ErpFeeStatus.gracePeriod.isEligibleForTracking, isTrue);
      expect(ErpFeeStatus.waived.isEligibleForTracking, isTrue);
      expect(ErpFeeStatus.pending.isEligibleForTracking, isFalse);
      expect(ErpFeeStatus.overdue.isEligibleForTracking, isFalse);
    });

    test('syncFromCollegeErp updates timestamps and returns sync result metadata', () async {
      final beforeSync = DateTime.now().subtract(const Duration(seconds: 1));
      final result = await mockManagerRepo.syncFromCollegeErp(collegeId: 'college-vjit');

      expect(result.provider, equals('vmax College ERP'));
      expect(result.totalFetched, greaterThanOrEqualTo(5));
      expect(result.paidCount, greaterThanOrEqualTo(2));
      expect(result.syncedAt.isAfter(beforeSync), isTrue);

      final students = await mockManagerRepo.getEnrolledStudents('college-vjit');
      for (final s in students) {
        expect(s.lastSyncedAt, isNotNull);
      }
    });

    test('syncFromCollegeErp accepts manual student batch and upserts records', () async {
      const newStudent = ErpStudent(
        id: 'stu-manual-1',
        rollNumber: '21911A0546',
        name: 'P. Sneha',
        email: '21911a0546@vjit.ac.in',
        phone: '+91 98480 66778',
        department: 'CSE',
        academicYear: '2025-26',
        section: 'CSE-B',
        routeId: 'route-12',
        routeName: 'Route 12 (Kukatpally)',
        stopName: 'KPHB Colony',
        feeStatus: ErpFeeStatus.paid,
        feeAmount: 32000,
        paidAmount: 32000,
        receiptNumber: 'VJIT/REC/2025/07194',
      );

      final result = await mockManagerRepo.syncFromCollegeErp(
        collegeId: 'college-vjit',
        manualStudents: [newStudent],
      );

      expect(result.totalFetched, greaterThanOrEqualTo(6));
      final students = await mockManagerRepo.getEnrolledStudents('college-vjit');
      final fetched = students.firstWhere((s) => s.rollNumber == '21911A0546');
      expect(fetched.name, equals('P. Sneha'));
      expect(fetched.feeStatus, equals(ErpFeeStatus.paid));
    });

    test('updateStudentFeeStatus modifies fee clearance and bus tracking eligibility', () async {
      // Initially, roll number 23911A0105 (M. Vikram Kumar) has pending status (not eligible)
      final initialStudents = await mockManagerRepo.getEnrolledStudents('college-vjit');
      final initialVikram = initialStudents.firstWhere((s) => s.rollNumber == '23911A0105');
      expect(initialVikram.feeStatus, equals(ErpFeeStatus.pending));
      expect(initialVikram.feeStatus.isEligibleForTracking, isFalse);

      // Transport manager grants 14-day grace period
      await mockManagerRepo.updateStudentFeeStatus(
        collegeId: 'college-vjit',
        rollNumber: '23911A0105',
        status: ErpFeeStatus.gracePeriod,
      );

      final updatedStudents = await mockManagerRepo.getEnrolledStudents('college-vjit');
      final updatedVikram = updatedStudents.firstWhere((s) => s.rollNumber == '23911A0105');
      expect(updatedVikram.feeStatus, equals(ErpFeeStatus.gracePeriod));
      expect(updatedVikram.feeStatus.isEligibleForTracking, isTrue);
    });

    test('erpSyncControllerProvider integrates with Riverpod and updates state', () async {
      final notifier = container.read(erpSyncControllerProvider.notifier);
      final syncResult = await notifier.triggerSync();

      expect(syncResult, isNotNull);
      expect(syncResult!.provider, equals('vmax College ERP'));

      final lastResult = container.read(lastErpSyncResultProvider);
      expect(lastResult, isNotNull);
      expect(lastResult!.totalFetched, equals(syncResult.totalFetched));
    });
  });
}
