import '../../core/models/app_user.dart';
import '../repositories/auth_repository.dart';
import 'mock_seed.dart';

/// Logs in as whichever seeded demo user's name (case-insensitive)
/// matches [username], as long as the password is "demo". Good enough
/// to exercise C1/C2/C3 in flow.md without a backend.
class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  @override
  Future<AppUser> login({
    required String collegeCode,
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400)); // feels like a network call

    if (password != 'demo') {
      // prd.md Module 1: "a clear, non-revealing error message"
      throw const AuthException('Incorrect username or password.');
    }

    final match = MockSeed.allDemoUsers.where(
      (u) => u.name.toLowerCase() == username.trim().toLowerCase(),
    );

    if (match.isEmpty) {
      throw const AuthException('Incorrect username or password.');
    }

    _currentUser = match.first;
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<AppUser?> restoreSession() async => _currentUser;
}
