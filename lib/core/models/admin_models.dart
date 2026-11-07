/// Status of a college on the platform (flow.md A3, prd.md Module 2).
enum CollegeStatus {
  active,
  deactivated,
  archived;

  String get label {
    switch (this) {
      case CollegeStatus.active:
        return 'Active';
      case CollegeStatus.deactivated:
        return 'Deactivated';
      case CollegeStatus.archived:
        return 'Archived';
    }
  }
}

/// Transport fee compliance policy enforced by a college (prd.md Module 2 & 14).
enum TransportFeePolicy {
  strictBlocking, // Student cannot view tracking if fees pending
  warningOnly,    // Warning banner shown, live tracking allowed
  gracePeriod;    // 14-day grace period before access restricted

  String get label {
    switch (this) {
      case TransportFeePolicy.strictBlocking:
        return 'Strict (Block on Unpaid)';
      case TransportFeePolicy.warningOnly:
        return 'Warning Only (Never Block)';
      case TransportFeePolicy.gracePeriod:
        return 'Grace Period (14 Days)';
    }
  }
}

/// College tenant entity managed by Master Admin (flow.md A1, prd.md Module 2).
class College {
  final String id;
  final String collegeCode;
  final String collegeName;
  final String? emailDomain;
  final String phone;
  final String email;
  final String city;
  final String state;
  final double campusLatitude;
  final double campusLongitude;
  final double campusRadiusMeters;
  final CollegeStatus status;
  final TransportFeePolicy feePolicy;
  final int totalBuses;
  final int totalDrivers;
  final int totalStudents;
  final DateTime createdAt;

  const College({
    required this.id,
    required this.collegeCode,
    required this.collegeName,
    this.emailDomain,
    required this.phone,
    required this.email,
    required this.city,
    required this.state,
    required this.campusLatitude,
    required this.campusLongitude,
    this.campusRadiusMeters = 250.0,
    this.status = CollegeStatus.active,
    this.feePolicy = TransportFeePolicy.warningOnly,
    this.totalBuses = 0,
    this.totalDrivers = 0,
    this.totalStudents = 0,
    required this.createdAt,
  });

  bool get isActive => status == CollegeStatus.active;

  College copyWith({
    String? id,
    String? collegeCode,
    String? collegeName,
    String? emailDomain,
    String? phone,
    String? email,
    String? city,
    String? state,
    double? campusLatitude,
    double? campusLongitude,
    double? campusRadiusMeters,
    CollegeStatus? status,
    TransportFeePolicy? feePolicy,
    int? totalBuses,
    int? totalDrivers,
    int? totalStudents,
    DateTime? createdAt,
  }) {
    return College(
      id: id ?? this.id,
      collegeCode: collegeCode ?? this.collegeCode,
      collegeName: collegeName ?? this.collegeName,
      emailDomain: emailDomain ?? this.emailDomain,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      state: state ?? this.state,
      campusLatitude: campusLatitude ?? this.campusLatitude,
      campusLongitude: campusLongitude ?? this.campusLongitude,
      campusRadiusMeters: campusRadiusMeters ?? this.campusRadiusMeters,
      status: status ?? this.status,
      feePolicy: feePolicy ?? this.feePolicy,
      totalBuses: totalBuses ?? this.totalBuses,
      totalDrivers: totalDrivers ?? this.totalDrivers,
      totalStudents: totalStudents ?? this.totalStudents,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Profile of a college transport manager account (flow.md A2, prd.md Module 2).
class CollegeManagerProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String collegeId;
  final String collegeName;
  final bool isActive;
  final DateTime createdAt;

  const CollegeManagerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.collegeId,
    required this.collegeName,
    this.isActive = true,
    required this.createdAt,
  });

  CollegeManagerProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? collegeId,
    String? collegeName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CollegeManagerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      collegeId: collegeId ?? this.collegeId,
      collegeName: collegeName ?? this.collegeName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Aggregate platform analytics visible to Master Admin (prd.md Module 13, §4.1).
class PlatformSummary {
  final int totalColleges;
  final int activeColleges;
  final int deactivatedColleges;
  final int archivedColleges;
  final int totalManagers;
  final int totalBuses;
  final int totalActiveTrips;

  const PlatformSummary({
    required this.totalColleges,
    required this.activeColleges,
    required this.deactivatedColleges,
    required this.archivedColleges,
    required this.totalManagers,
    required this.totalBuses,
    required this.totalActiveTrips,
  });
}
