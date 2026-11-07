import '../../core/models/admin_models.dart';

/// Abstract contract for Master Admin operations (flow.md A1–A3, prd.md Module 2).
abstract class AdminRepository {
  /// Fetch platform-level aggregate summary metrics.
  Future<PlatformSummary> getPlatformSummary();

  /// List all colleges registered on the platform.
  Future<List<College>> getColleges();

  /// Retrieve a specific college by ID.
  Future<College?> getCollegeById(String collegeId);

  /// Create or update a college profile and configuration.
  Future<College> saveCollege(College college);

  /// Change college lifecycle status (Active / Deactivated / Archived).
  Future<void> setCollegeStatus(String collegeId, CollegeStatus status);

  /// List transport manager accounts (optionally filtered by college).
  Future<List<CollegeManagerProfile>> getManagers({String? collegeId});

  /// Provision a new transport manager account.
  Future<CollegeManagerProfile> createManager({
    required String collegeId,
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Activate or deactivate a manager's access.
  Future<void> toggleManagerStatus({
    required String managerId,
    required bool isActive,
  });
}
