/// Transport fee status from College ERP ledger.
enum ErpFeeStatus {
  paid,
  pending,
  overdue,
  gracePeriod,
  waived;

  String get label {
    switch (this) {
      case ErpFeeStatus.paid:
        return 'Paid';
      case ErpFeeStatus.pending:
        return 'Pending';
      case ErpFeeStatus.overdue:
        return 'Overdue';
      case ErpFeeStatus.gracePeriod:
        return 'Grace Period (14d)';
      case ErpFeeStatus.waived:
        return 'Fee Waived';
    }
  }

  bool get isEligibleForTracking =>
      this == ErpFeeStatus.paid ||
      this == ErpFeeStatus.gracePeriod ||
      this == ErpFeeStatus.waived;
}

/// Student record ingested from College ERP (e.g., vmax, CampX).
class ErpStudent {
  final String id;
  final String rollNumber;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String academicYear;
  final String section;
  final String routeId;
  final String routeName;
  final String stopName;
  final ErpFeeStatus feeStatus;
  final double feeAmount;
  final double paidAmount;
  final String? receiptNumber;
  final DateTime? lastSyncedAt;

  const ErpStudent({
    required this.id,
    required this.rollNumber,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.academicYear,
    required this.section,
    required this.routeId,
    required this.routeName,
    required this.stopName,
    required this.feeStatus,
    required this.feeAmount,
    required this.paidAmount,
    this.receiptNumber,
    this.lastSyncedAt,
  });

  ErpStudent copyWith({
    String? id,
    String? rollNumber,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? academicYear,
    String? section,
    String? routeId,
    String? routeName,
    String? stopName,
    ErpFeeStatus? feeStatus,
    double? feeAmount,
    double? paidAmount,
    String? receiptNumber,
    DateTime? lastSyncedAt,
  }) {
    return ErpStudent(
      id: id ?? this.id,
      rollNumber: rollNumber ?? this.rollNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      section: section ?? this.section,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      stopName: stopName ?? this.stopName,
      feeStatus: feeStatus ?? this.feeStatus,
      feeAmount: feeAmount ?? this.feeAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Batch sync metrics returned after an ERP sync operation.
class ErpSyncResult {
  final int totalFetched;
  final int createdCount;
  final int updatedCount;
  final int paidCount;
  final int pendingCount;
  final String provider;
  final DateTime syncedAt;

  const ErpSyncResult({
    required this.totalFetched,
    required this.createdCount,
    required this.updatedCount,
    required this.paidCount,
    required this.pendingCount,
    required this.provider,
    required this.syncedAt,
  });
}
