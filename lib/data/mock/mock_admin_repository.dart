import 'dart:async';

import '../../core/models/admin_models.dart';
import '../repositories/admin_repository.dart';

/// In-memory mock implementation of [AdminRepository] (flow.md A1–A3).
class MockAdminRepository implements AdminRepository {
  static final List<College> _colleges = [
    College(
      id: 'college-vjit',
      collegeCode: 'VJIT',
      collegeName: 'Vidya Jyothi Institute of Technology',
      emailDomain: 'vjit.ac.in',
      phone: '+91 8413 235300',
      email: 'transport@vjit.ac.in',
      city: 'Hyderabad',
      state: 'Telangana',
      campusLatitude: 17.3605,
      campusLongitude: 78.3615,
      campusRadiusMeters: 300.0,
      status: CollegeStatus.active,
      feePolicy: TransportFeePolicy.warningOnly,
      totalBuses: 3,
      totalDrivers: 3,
      totalStudents: 1420,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    College(
      id: 'college-cbit',
      collegeCode: 'CBIT',
      collegeName: 'Chaitanya Bharathi Institute of Technology',
      emailDomain: 'cbit.ac.in',
      phone: '+91 8466 900999',
      email: 'admin@cbit.ac.in',
      city: 'Gandipet, Hyderabad',
      state: 'Telangana',
      campusLatitude: 17.3916,
      campusLongitude: 78.3194,
      campusRadiusMeters: 400.0,
      status: CollegeStatus.active,
      feePolicy: TransportFeePolicy.strictBlocking,
      totalBuses: 12,
      totalDrivers: 12,
      totalStudents: 2800,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    College(
      id: 'college-vce',
      collegeCode: 'VCE',
      collegeName: 'Vasavi College of Engineering',
      emailDomain: 'vce.ac.in',
      phone: '+91 40 2314 6003',
      email: 'transport@vce.ac.in',
      city: 'Ibrahimbagh, Hyderabad',
      state: 'Telangana',
      campusLatitude: 17.3803,
      campusLongitude: 78.3826,
      campusRadiusMeters: 250.0,
      status: CollegeStatus.deactivated,
      feePolicy: TransportFeePolicy.gracePeriod,
      totalBuses: 8,
      totalDrivers: 8,
      totalStudents: 1950,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  static final List<CollegeManagerProfile> _managers = [
    CollegeManagerProfile(
      id: 'user-manager-1',
      name: 'Priya Nair',
      email: 'priya.nair@vjit.ac.in',
      phone: '+91 98480 12345',
      collegeId: 'college-vjit',
      collegeName: 'Vidya Jyothi Institute of Technology',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    ),
    CollegeManagerProfile(
      id: 'user-manager-2',
      name: 'Dr. K. Srinivas',
      email: 'ksrinivas@cbit.ac.in',
      phone: '+91 98490 54321',
      collegeId: 'college-cbit',
      collegeName: 'Chaitanya Bharathi Institute of Technology',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 85)),
    ),
    CollegeManagerProfile(
      id: 'user-manager-3',
      name: 'B. Maheshwar',
      email: 'b.maheshwar@vce.ac.in',
      phone: '+91 99887 76655',
      collegeId: 'college-vce',
      collegeName: 'Vasavi College of Engineering',
      isActive: false,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ),
  ];

  @override
  Future<PlatformSummary> getPlatformSummary() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final active = _colleges.where((c) => c.status == CollegeStatus.active).length;
    final deactivated = _colleges.where((c) => c.status == CollegeStatus.deactivated).length;
    final archived = _colleges.where((c) => c.status == CollegeStatus.archived).length;
    final totalBuses = _colleges.fold<int>(0, (acc, c) => acc + c.totalBuses);

    return PlatformSummary(
      totalColleges: _colleges.length,
      activeColleges: active,
      deactivatedColleges: deactivated,
      archivedColleges: archived,
      totalManagers: _managers.length,
      totalBuses: totalBuses,
      totalActiveTrips: 2,
    );
  }

  @override
  Future<List<College>> getColleges() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_colleges);
  }

  @override
  Future<College?> getCollegeById(String collegeId) async {
    await Future.delayed(const Duration(milliseconds: 60));
    try {
      return _colleges.firstWhere((c) => c.id == collegeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<College> saveCollege(College college) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _colleges.indexWhere((c) => c.id == college.id);
    if (index >= 0) {
      _colleges[index] = college;
    } else {
      _colleges.add(college);
    }
    return college;
  }

  @override
  Future<void> setCollegeStatus(String collegeId, CollegeStatus status) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final index = _colleges.indexWhere((c) => c.id == collegeId);
    if (index >= 0) {
      _colleges[index] = _colleges[index].copyWith(status: status);
    }
  }

  @override
  Future<List<CollegeManagerProfile>> getManagers({String? collegeId}) async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (collegeId == null) {
      return List.unmodifiable(_managers);
    }
    return List.unmodifiable(_managers.where((m) => m.collegeId == collegeId));
  }

  @override
  Future<CollegeManagerProfile> createManager({
    required String collegeId,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final college = _colleges.firstWhere(
      (c) => c.id == collegeId,
      orElse: () => _colleges.first,
    );

    final manager = CollegeManagerProfile(
      id: 'manager-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      collegeId: college.id,
      collegeName: college.collegeName,
      isActive: true,
      createdAt: DateTime.now(),
    );

    _managers.add(manager);
    return manager;
  }

  @override
  Future<void> toggleManagerStatus({
    required String managerId,
    required bool isActive,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _managers.indexWhere((m) => m.id == managerId);
    if (index >= 0) {
      _managers[index] = _managers[index].copyWith(isActive: isActive);
    }
  }
}
