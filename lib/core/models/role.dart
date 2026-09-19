/// The five roles from prd.md §4. One app, one login, the role decides
/// which feature module (lib/features/<role>/) the router sends the
/// user to — see app/router.dart.
enum UserRole {
  masterAdmin,
  manager, // "transport_admin" in the backend — see BACKEND_CHANGES.md
  driver,
  student,
  faculty;

  String get label {
    switch (this) {
      case UserRole.masterAdmin:
        return 'Master Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.driver:
        return 'Driver';
      case UserRole.student:
        return 'Student';
      case UserRole.faculty:
        return 'Faculty';
    }
  }

  /// C2 in flow.md: which home route a role lands on after login.
  String get homeRoute {
    switch (this) {
      case UserRole.masterAdmin:
        return '/admin';
      case UserRole.manager:
        return '/manager';
      case UserRole.driver:
        return '/driver';
      case UserRole.student:
      case UserRole.faculty:
        return '/student';
    }
  }
}
