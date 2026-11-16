import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/app_user.dart';
import '../data/mock/mock_admin_repository.dart';
import '../data/mock/mock_auth_repository.dart';
import '../data/mock/mock_driver_repository.dart';
import '../data/mock/mock_manager_repository.dart';
import '../data/mock/mock_transport_repository.dart';
import '../data/remote/remote_admin_repository.dart';
import '../data/remote/remote_auth_repository.dart';
import '../data/remote/remote_driver_repository.dart';
import '../data/remote/remote_manager_repository.dart';
import '../data/remote/remote_transport_repository.dart';
import '../data/remote/supabase_client_provider.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/driver_repository.dart';
import '../data/repositories/manager_repository.dart';
import '../data/repositories/transport_repository.dart';

/// THE SWITCH POINT.
///
/// Every screen depends on the abstract repository types, never on
/// a concrete implementation directly. When Supabase is configured and
/// active, remote repositories connect to live tables and PL/pgSQL RPCs.
/// When offline or during tests, mock implementations provide full fidelity.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return RemoteAuthRepository(client);
  }
  return MockAuthRepository();
});

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return RemoteTransportRepository(client);
  }
  return MockTransportRepository();
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return RemoteDriverRepository(client);
  }
  return MockDriverRepository();
});

final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return RemoteManagerRepository(client);
  }
  return MockManagerRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return RemoteAdminRepository(client);
  }
  return MockAdminRepository();
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

final authControllerProvider =
    StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
