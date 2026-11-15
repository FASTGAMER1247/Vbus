import 'package:flutter_test/flutter_test.dart';
import 'package:campus_transit/core/models/compliance_models.dart';
import 'package:campus_transit/core/models/driver_models.dart';
import 'package:campus_transit/data/mock/mock_driver_repository.dart';
import 'package:campus_transit/data/mock/mock_manager_repository.dart';

void main() {
  group('Driver QR Scanning, Unassigned Takeover & Compliance Tests', () {
    late MockDriverRepository driverRepo;
    late MockManagerRepository managerRepo;

    setUp(() {
      driverRepo = MockDriverRepository();
      managerRepo = MockManagerRepository();
    });

    test('Assigned driver scanning valid bus QR starts trip cleanly', () async {
      final result = await driverRepo.identifyBus(
        driverId: 'driver-1',
        busIdOrCode: 'CAMPUS_TRANSIT:BUS:VJIT:023',
      );

      expect(result.trip.bus.busNumber, '023');
      expect(result.isUnassignedTakeover, isFalse);
      expect(result.advisoryAlert, isNull);
    });

    test('Unassigned driver can take over available bus if validations pass', () async {
      // Driver has no pre-assignment, but Bus 015 is idle & belonging to college
      final result = await driverRepo.identifyBus(
        driverId: 'driver-unassigned',
        busIdOrCode: '015',
      );

      expect(result.trip.bus.busNumber, '015');
      expect(result.isUnassignedTakeover, isTrue);
    });

    test('Bus with expired insurance blocks trip with busDocumentExpired exception', () async {
      try {
        await driverRepo.identifyBus(
          driverId: 'driver-1',
          busIdOrCode: '042', // Bus TS 09 EF 9012 has expired insurance
        );
        fail('Should have thrown DriverBlockedException');
      } on DriverBlockedException catch (e) {
        expect(e.reason, DriverBlockReason.busDocumentExpired);
        expect(e.documentAlert, isNotNull);
        expect(e.documentAlert!.documentType, DocumentType.insurancePolicy);
        expect(e.documentAlert!.isExpired, isTrue);
        expect(e.documentAlert!.blocksTrip, isTrue);
      }
    });

    test('Bus with document expiring soon (PUC in 5 days) allows trip with advisoryAlert', () async {
      final result = await driverRepo.identifyBus(
        driverId: 'driver-1',
        busIdOrCode: '009',
      );

      expect(result.trip.bus.busNumber, '009');
      expect(result.advisoryAlert, isNotNull);
      expect(result.advisoryAlert!.documentType, DocumentType.pucCertificate);
      expect(result.advisoryAlert!.daysUntilExpiry, 5);
      expect(result.advisoryAlert!.isExpiringSoon, isTrue);
    });

    test('Driver with expired commercial license is blocked from starting trip', () async {
      try {
        await driverRepo.identifyBus(
          driverId: 'driver-2', // Suresh V has expired DL
          busIdOrCode: '023',
        );
        fail('Should have thrown DriverBlockedException');
      } on DriverBlockedException catch (e) {
        expect(e.reason, DriverBlockReason.driverLicenseExpired);
        expect(e.documentAlert, isNotNull);
        expect(e.documentAlert!.documentType, DocumentType.drivingLicense);
        expect(e.documentAlert!.isExpired, isTrue);
      }
    });

    test('Manager CRM retrieves all compliance alerts with severity counts', () async {
      final alerts = await managerRepo.getComplianceAlerts('college-vjit');
      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.isExpired), isTrue);
      expect(alerts.any((a) => a.isExpiringSoon), isTrue);

      final summary = await managerRepo.getFleetSummary('college-vjit');
      expect(summary.complianceWarningsCount, greaterThan(0));
    });
  });
}
