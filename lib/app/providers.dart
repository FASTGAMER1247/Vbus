import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/app_user.dart';
import '../data/mock/mock_auth_repository.dart';
import '../data/mock/mock_driver_repository.dart';
import '../data/mock/mock_transport_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/driver_repository.dart';
import '../data/repositories/transport_repository.dart';

/// THE SWITCH POINT.
///
/// Every screen depends on the abstract repository types, never on
/// Mock*Repository directly. When the backend contract is ready
/// (BACKEND_CHANGES.md), write data/remote/remote_auth_repository.dart
/// and data/remote/remote_transport_repository.dart against the same
/// interfaces, then change exactly these lines. No screen changes.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  return MockTransportRepository();
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return MockDriverRepository();
});

/// Current signed-in user. Null = logged out. app/router.dart watches
/// this for C1/C2/C3 redirects (flow.md).
class AuthController extends StateNotifier<AppUser?> {
  AuthController(this._repo) : super(null) {
    _restore();
  }

  final AuthRepository _repo;

  Future<void> _restore() async {
    state = await _repo.restoreSession();
  }

  Future<void> login({
    required String collegeCode,
    required String username,
    required String password,
  }) async {
    state = await _repo.login(
      collegeCode: collegeCode,
      username: username,
      password: password,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = null;
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
