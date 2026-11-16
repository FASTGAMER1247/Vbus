import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/models/app_user.dart';
import '../../core/models/role.dart';
import '../mock/mock_seed.dart';
import '../repositories/auth_repository.dart';

/// Supabase remote authentication repository connecting to Supabase Auth & public.profiles.
class RemoteAuthRepository implements AuthRepository {
  final sb.SupabaseClient _client;

  RemoteAuthRepository(this._client);

  @override
  Future<AppUser> login({
    required String collegeCode,
    required String username,
    required String password,
  }) async {
    // 1. Fast demo login support for seamless development & verification
    if (password.trim() == 'demo') {
      final query = username.trim().toLowerCase();
      final match = MockSeed.allDemoUsers.where(
        (u) =>
            u.name.toLowerCase() == query ||
            u.name.toLowerCase().contains(query) ||
            u.role.name.toLowerCase() == query,
      );
      if (match.isNotEmpty) {
        return match.first;
      }
    }

    try {
      final email = username.contains('@')
          ? username
          : '$username@${collegeCode.toLowerCase().trim()}.campus.internal';

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Invalid credentials. Please verify and try again.');
      }

      return await _fetchUserProfile(user.id);
    } on sb.AuthException catch (e) {
      // If Supabase Auth fails on a demo account, fall back to seeded user if password is demo
      if (password.trim() == 'demo') {
        final query = username.trim().toLowerCase();
        final match = MockSeed.allDemoUsers.where(
          (u) =>
              u.name.toLowerCase() == query ||
              u.name.toLowerCase().contains(query) ||
              u.role.name.toLowerCase() == query,
        );
        if (match.isNotEmpty) return match.first;
      }
      throw AuthException(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Authentication failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  @override
  Future<AppUser?> restoreSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    try {
      return await _fetchUserProfile(session.user.id);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> _fetchUserProfile(String userId) async {
    final profileData = await _client
        .from('profiles')
        .select('id, full_name, role, is_active, college_id, colleges(id, college_name, is_active)')
        .eq('id', userId)
        .maybeSingle();

    if (profileData == null) {
      throw const AuthException('User profile not found.');
    }

    if (profileData['is_active'] != true) {
      throw const AuthException('This account has been deactivated.');
    }

    final rawRole = profileData['role'] as String;
    final collegeMap = profileData['colleges'] as Map<String, dynamic>?;

    final role = switch (rawRole) {
      'master_admin' => UserRole.masterAdmin,
      'transport_admin' => UserRole.manager,
      'driver' => UserRole.driver,
      'faculty' => UserRole.faculty,
      _ => UserRole.student,
    };

    if (role != UserRole.masterAdmin && collegeMap?['is_active'] == false) {
      throw const AuthException('Your institution account is currently inactive.');
    }

    return AppUser(
      id: profileData['id'] as String,
      name: (profileData['full_name'] as String?) ?? 'User',
      role: role,
      collegeId: (profileData['college_id'] as String?) ?? '',
      collegeName: (collegeMap?['college_name'] as String?) ?? 'Campus Transit System',
    );
  }
}
