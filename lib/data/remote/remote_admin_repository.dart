import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/models/admin_models.dart';
import '../repositories/admin_repository.dart';

/// Supabase remote admin repository for multi-college management & platform operations.
class RemoteAdminRepository implements AdminRepository {
  final sb.SupabaseClient _client;

  RemoteAdminRepository(this._client);

  @override
  Future<PlatformSummary> getPlatformSummary() async {
    try {
      final collegesRes = await _client.from('colleges').select('id, is_active');
      final busesRes = await _client.from('buses').select('id');
      final tripsRes = await _client.from('trips').select('id, status').eq('status', 'active');
      final managersRes = await _client.from('profiles').select('id').eq('role', 'transport_admin');

      final totalColleges = collegesRes.length;
      final activeColleges = collegesRes.where((c) => c['is_active'] == true).length;
      final deactivatedColleges = totalColleges - activeColleges;

      return PlatformSummary(
        totalColleges: totalColleges,
        activeColleges: activeColleges,
        deactivatedColleges: deactivatedColleges,
        archivedColleges: 0,
        totalManagers: managersRes.length,
        totalBuses: busesRes.length,
        totalActiveTrips: tripsRes.length,
      );
    } catch (_) {
      return const PlatformSummary(
        totalColleges: 0,
        activeColleges: 0,
        deactivatedColleges: 0,
        archivedColleges: 0,
        totalManagers: 0,
        totalBuses: 0,
        totalActiveTrips: 0,
      );
    }
  }

  @override
  Future<List<College>> getColleges() async {
    final res = await _client.from('colleges').select().order('created_at', ascending: false);
    return (res as List<dynamic>).map((c) => _mapCollege(c as Map<String, dynamic>)).toList();
  }

  @override
  Future<College?> getCollegeById(String collegeId) async {
    final res = await _client.from('colleges').select().eq('id', collegeId).maybeSingle();
    if (res == null) return null;
    return _mapCollege(res);
  }

  @override
  Future<College> saveCollege(College college) async {
    final data = {
      if (college.id.isNotEmpty && !college.id.startsWith('college-')) 'id': college.id,
      'college_name': college.collegeName,
      'college_code': college.collegeCode,
      'city': college.city,
      'state': college.state,
      'phone': college.phone,
      'email': college.email,
      'is_active': college.status == CollegeStatus.active,
    };

    final res = await _client.from('colleges').upsert(data).select().single();
    return _mapCollege(res);
  }

  @override
  Future<void> setCollegeStatus(String collegeId, CollegeStatus status) async {
    await _client.from('colleges').update({
      'is_active': status == CollegeStatus.active,
    }).eq('id', collegeId);
  }

  @override
  Future<List<CollegeManagerProfile>> getManagers({String? collegeId}) async {
    var query = _client
        .from('profiles')
        .select('id, full_name, role, phone, is_active, college_id, created_at, colleges(id, college_name)')
        .eq('role', 'transport_admin');

    if (collegeId != null && collegeId.isNotEmpty) {
      query = query.eq('college_id', collegeId);
    }

    final res = await query;
    return (res as List<dynamic>).map((p) {
      final col = p['colleges'] as Map<String, dynamic>? ?? {};
      return CollegeManagerProfile(
        id: p['id'] as String,
        name: (p['full_name'] as String?) ?? 'Transport Admin',
        email: '${p['id']}@campus.transit',
        phone: (p['phone'] as String?) ?? '',
        collegeId: (p['college_id'] as String?) ?? '',
        collegeName: (col['college_name'] as String?) ?? 'College',
        isActive: p['is_active'] == true,
        createdAt: DateTime.tryParse(p['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<CollegeManagerProfile> createManager({
    required String collegeId,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // Provision using backend RPC provision_account
    final res = await _client.rpc('provision_account', params: {
      'p_email': email,
      'p_role': 'transport_admin',
      'p_college_id': collegeId,
      'p_full_name': name,
      'p_phone': phone,
    });

    final map = res is Map<String, dynamic> ? res : <String, dynamic>{};
    final newId = (map['user_id'] as String?) ?? (map['profile_id'] as String?) ?? email;

    return CollegeManagerProfile(
      id: newId,
      name: name,
      email: email,
      phone: phone,
      collegeId: collegeId,
      collegeName: 'College',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> toggleManagerStatus({
    required String managerId,
    required bool isActive,
  }) async {
    await _client.from('profiles').update({'is_active': isActive}).eq('id', managerId);
  }

  College _mapCollege(Map<String, dynamic> m) {
    final isActive = m['is_active'] == true;
    return College(
      id: m['id'] as String,
      collegeName: (m['college_name'] as String?) ?? (m['name'] as String?) ?? 'Campus',
      collegeCode: (m['college_code'] as String?) ?? (m['code'] as String?) ?? '',
      city: (m['city'] as String?) ?? '',
      state: (m['state'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      phone: (m['phone'] as String?) ?? '',
      status: isActive ? CollegeStatus.active : CollegeStatus.deactivated,
      campusLatitude: (m['latitude'] as num?)?.toDouble() ?? 12.9716,
      campusLongitude: (m['longitude'] as num?)?.toDouble() ?? 77.5946,
      campusRadiusMeters: (m['geofence_radius_meters'] as num?)?.toDouble() ?? 300.0,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
