/// Document types tracked for fleet compliance (BUS_APP Phase 25).
enum DocumentType {
  drivingLicense,
  medicalCertificate,
  policeVerification,
  rcBook,
  fitnessCertificate,
  insurancePolicy,
  pucCertificate,
  permit,
  roadTax;

  String get label {
    switch (this) {
      case DocumentType.drivingLicense:
        return 'Driver Commercial License';
      case DocumentType.medicalCertificate:
        return 'Medical Fitness Certificate';
      case DocumentType.policeVerification:
        return 'Police Background Verification';
      case DocumentType.rcBook:
        return 'Vehicle Registration (RC)';
      case DocumentType.fitnessCertificate:
        return 'Vehicle Fitness Certificate';
      case DocumentType.insurancePolicy:
        return 'Commercial Vehicle Insurance';
      case DocumentType.pucCertificate:
        return 'Pollution Certificate (PUC)';
      case DocumentType.permit:
        return 'College Transport Permit';
      case DocumentType.roadTax:
        return 'State Road Tax Receipt';
    }
  }

  bool get isDriverDoc =>
      this == DocumentType.drivingLicense ||
      this == DocumentType.medicalCertificate ||
      this == DocumentType.policeVerification;

  bool get isBusDoc => !isDriverDoc;
}

/// Expiry status of a legal or compliance document.
enum ComplianceSeverity {
  valid,
  expiringSoon, // <= 30 days remaining
  expired;

  String get label {
    switch (this) {
      case ComplianceSeverity.valid:
        return 'Valid';
      case ComplianceSeverity.expiringSoon:
        return 'Expiring Soon';
      case ComplianceSeverity.expired:
        return 'Expired';
    }
  }
}

/// Alert or warning generated for an expiring/expired document (flow.md D5 / M2).
class DocumentAlert {
  final String id;
  final String collegeId;
  final String entityType; // 'driver' or 'bus'
  final String entityId;
  final String entityName; // e.g. "Ramesh K" or "Bus 023"
  final DocumentType documentType;
  final String documentNumber;
  final DateTime expiryDate;
  final ComplianceSeverity severity;
  final int daysUntilExpiry;
  final bool blocksTrip;

  const DocumentAlert({
    required this.id,
    required this.collegeId,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.documentType,
    required this.documentNumber,
    required this.expiryDate,
    required this.severity,
    required this.daysUntilExpiry,
    this.blocksTrip = true,
  });

  bool get isExpired => severity == ComplianceSeverity.expired;
  bool get isExpiringSoon => severity == ComplianceSeverity.expiringSoon;
}
