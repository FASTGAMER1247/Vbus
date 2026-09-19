import '../../core/models/app_user.dart';

/// Screens only ever depend on this interface (see data/mock/ for the
/// implementation used today, and data/remote/ for the Supabase one
/// to write once the backend's account-provisioning gap is closed —
/// BACKEND_CHANGES.md item #7). Swapping the provider override in
/// app/providers.dart is the only change needed when that happens.
abstract class AuthRepository {
  /// flow.md C1. Throws an [AuthException] with a non-revealing
  /// message on bad credentials, per prd.md Module 1 rule:
  /// "Wrong credentials give a clear, non-revealing error message."
  Future<AppUser> login({
    required String collegeCode,
    required String username,
    required String password,
  });

  Future<void> logout();

  /// Restores a session on app start (flow.md C1: "Already logged in
  /// with a valid session?"). Returns null if there isn't one.
  Future<AppUser?> restoreSession();
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
