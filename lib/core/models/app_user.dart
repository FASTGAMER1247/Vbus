import 'role.dart';

/// The person who is logged in. Deliberately thin — role-specific
/// detail (a driver's assigned bus, a student's route) lives in that
/// role's own repository, not bolted onto this model.
class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String collegeId;
  final String collegeName;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.collegeId,
    required this.collegeName,
  });
}
