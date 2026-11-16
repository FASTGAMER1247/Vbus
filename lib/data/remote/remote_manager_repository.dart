import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/models/compliance_models.dart';
import '../../core/models/driver_models.dart';
import '../../core/models/manager_models.dart';
import '../../core/models/transport_models.dart';
import '../../core/models/trip_stage.dart';
import '../repositories/manager_repository.dart';

/// Supabase remote manager repository connecting transport manager CRM to backend tables and RPCs.
class RemoteManagerRepository implements ManagerRepository {
  final sb.SupabaseClient _client;

  RemoteManagerRepository(this._client);

  @override
  Future<FleetSummary> getFleetSummary(String collegeId) async {
    try {
      final busesRes = await _client.from('buses').select('id, is_active').eq('college_id', collegeId);
      final tripsRes = await _client.from('trips').select('id, status').eq('college_id', collegeId);
      final complianceAlerts = await getComplianceAlerts(collegeId);

      final totalBuses = busesRes.length;
      final activeBuses = tripsRes.where((t) => t['status'] == 'active').length;
      final inactiveBuses = totalBuses - activeBuses;
      final activeTrips = activeBuses;
      final completedTrips = tripsRes.where((t) => t['status'] == 'completed').length;

      return FleetSummary(
        activeBuses: activeBuses,
        inactiveBuses: inactiveBuses,
        activeTrips: activeTrips,
        completedTrips: completedTrips,
        offlineBuses: 0,
        complianceWarningsCount: complianceAlerts.length,
      );
    } catch (_) {
      return const FleetSummary(
        activeBuses: 0,
        inactiveBuses: 0,
        activeTrips: 0,
        completedTrips: 0,
        offlineBuses: 0,
        complianceWarningsCount: 0,
      );
    }
  }

  @override
  Future<List<Bus>> getBuses(String collegeId) async {
    final res = await _client
        .from('buses')
        .select('id, bus_number, registration_number, capacity')
        .eq('college_id', collegeId)
        .order('bus_number');

    return (res as List<dynamic>).map((b) => Bus(
      id: b['id'] as String,
      busNumber: b['bus_number'] as String,
      registrationNumber: b['registration_number'] as String?,
      capacity: b['capacity'] as int?,
    )).toList();
  }

  @override
  Future<Bus> saveBus({required String collegeId, required Bus bus}) async {
    final data = {
      'college_id': collegeId,
      'bus_number': bus.busNumber,
      'registration_number': bus.registrationNumber,
      'capacity': bus.capacity ?? 40,
      'is_active': true,
      'qr_code': bus.busNumber,
    };

    if (bus.id.isNotEmpty && !bus.id.startsWith('bus-')) {
      data['id'] = bus.id;
    }

    final res = await _client.from('buses').upsert(data).select().single();
    return Bus(
      id: res['id'] as String,
      busNumber: res['bus_number'] as String,
      registrationNumber: res['registration_number'] as String?,
      capacity: res['capacity'] as int?,
    );
  }

  @override
  Future<void> deleteBus(String busId) async {
    await _client.from('buses').delete().eq('id', busId);
  }

  @override
  Future<List<DriverProfile>> getDrivers(String collegeId) async {
    final res = await _client
        .from('drivers')
        .select('id, driver_code, profiles(full_name, phone)')
        .eq('college_id', collegeId);

    return (res as List<dynamic>).map((d) {
      final p = d['profiles'] as Map<String, dynamic>? ?? {};
      return DriverProfile(
        id: d['id'] as String,
        name: (p['full_name'] as String?) ?? (d['driver_code'] as String),
        phone: (p['phone'] as String?) ?? '',
      );
    }).toList();
  }

  @override
  Future<DriverProfile> saveDriver({required String collegeId, required DriverProfile driver}) async {
    final res = await _client.from('drivers').upsert({
      if (driver.id.isNotEmpty && !driver.id.startsWith('driver-')) 'id': driver.id,
      'college_id': collegeId,
      'driver_code': driver.name.replaceAll(' ', '_').toUpperCase(),
      'verification_status': 'verified',
    }).select().single();

    return DriverProfile(
      id: res['id'] as String,
      name: driver.name,
      phone: driver.phone,
    );
  }

  @override
  Future<void> deleteDriver(String driverId) async {
    await _client.from('drivers').delete().eq('id', driverId);
  }

  @override
  Future<List<TransportRoute>> getRoutes(String collegeId) async {
    final res = await _client
        .from('routes')
        .select('id, name, estimated_distance_km, route_stops(id, stop_order, expected_time, stops(id, name, latitude, longitude))')
        .eq('college_id', collegeId);

    return (res as List<dynamic>).map((r) => _mapRoute(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<TransportRoute> saveRoute({required String collegeId, required TransportRoute route}) async {
    final res = await _client.from('routes').upsert({
      if (route.id.isNotEmpty && !route.id.startsWith('route-')) 'id': route.id,
      'college_id': collegeId,
      'name': route.name,
      'estimated_distance_km': route.estimatedDistanceKm,
    }).select().single();

    return TransportRoute(
      id: res['id'] as String,
      name: res['name'] as String,
      stops: route.stops,
      estimatedDistanceKm: (res['estimated_distance_km'] as num?)?.toDouble(),
    );
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    await _client.from('routes').delete().eq('id', routeId);
  }

  @override
  Future<List<FleetAssignment>> getAssignments(String collegeId) async {
    final res = await _client
        .from('driver_transport_assignments')
        .select('id, is_active, bus_id, driver_id, route_id, effective_from')
        .eq('college_id', collegeId);

    return (res as List<dynamic>).map((a) {
      return FleetAssignment(
        id: a['id'] as String,
        collegeId: collegeId,
        busId: (a['bus_id'] as String?) ?? '',
        driverId: (a['driver_id'] as String?) ?? '',
        routeId: (a['route_id'] as String?) ?? '',
        assignedAt: DateTime.tryParse(a['effective_from'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<FleetAssignment> saveAssignment(FleetAssignment assignment) async {
    final res = await _client.from('driver_transport_assignments').upsert({
      if (assignment.id.isNotEmpty && !assignment.id.startsWith('assign-')) 'id': assignment.id,
      'college_id': assignment.collegeId,
      'bus_id': assignment.busId,
      'driver_id': assignment.driverId,
      'route_id': assignment.routeId,
      'is_active': true,
      'effective_from': assignment.assignedAt.toIso8601String().substring(0, 10),
    }).select().single();

    return assignment.copyWith(id: res['id'] as String);
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    await _client.from('driver_transport_assignments').delete().eq('id', assignmentId);
  }

  @override
  Future<List<Trip>> getTrips(String collegeId) async {
    final res = await _client
        .from('trips')
        .select('''
          id, status, scheduled_date, scheduled_departure_time, actual_start_at, completed_at,
          buses(id, bus_number, registration_number, capacity),
          routes(id, name, estimated_distance_km, route_stops(id, stop_order, expected_time, stops(id, name, latitude, longitude))),
          drivers(id, profile_id, driver_code, profiles(full_name, phone))
        ''')
        .eq('college_id', collegeId)
        .order('created_at', ascending: false);

    return (res as List<dynamic>).map((t) => _mapTrip(t as Map<String, dynamic>)).toList();
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    final res = await _client
        .from('trips')
        .select('''
          id, status, scheduled_date, scheduled_departure_time, actual_start_at, completed_at,
          buses(id, bus_number, registration_number, capacity),
          routes(id, name, estimated_distance_km, route_stops(id, stop_order, expected_time, stops(id, name, latitude, longitude))),
          drivers(id, profile_id, driver_code, profiles(full_name, phone))
        ''')
        .eq('id', tripId)
        .maybeSingle();

    if (res == null) return null;
    return _mapTrip(res);
  }

  @override
  Future<Trip> createScheduledTrip(CreateTripParams params) async {
    final res = await _client.from('trips').insert({
      'college_id': params.collegeId,
      'bus_id': params.busId,
      'driver_id': params.driverId,
      'route_id': params.routeId,
      'scheduled_date': DateTime.now().toIso8601String().substring(0, 10),
      'scheduled_departure_time': '07:30:00',
      'status': 'scheduled',
    }).select('id').single();

    final trip = await getTripById(res['id'] as String);
    if (trip == null) throw StateError('Failed to retrieve newly created trip');
    return trip;
  }

  @override
  Future<void> endStuckTrip({required String tripId, required String managerId}) async {
    await _client.rpc('complete_trip', params: {
      'p_trip_id': tripId,
      'p_end_reason': 'transport_admin_override',
    });
  }

  @override
  Stream<List<FleetBusLocation>> watchFleetLocations(String collegeId) {
    late StreamController<List<FleetBusLocation>> controller;
    sb.RealtimeChannel? channel;

    controller = StreamController<List<FleetBusLocation>>.broadcast(
      onListen: () async {
        final initial = await _fetchFleetLocations(collegeId);
        controller.add(initial);

        channel = _client.channel('manager_fleet_locations_$collegeId')
          ..onPostgresChanges(
            event: sb.PostgresChangeEvent.all,
            schema: 'public',
            table: 'bus_live_locations',
            callback: (_) async {
              final updated = await _fetchFleetLocations(collegeId);
              controller.add(updated);
            },
          )
          ..subscribe();
      },
      onCancel: () {
        if (channel != null) {
          _client.removeChannel(channel!);
        }
      },
    );

    return controller.stream;
  }

  Future<List<FleetBusLocation>> _fetchFleetLocations(String collegeId) async {
    try {
      final res = await _client
          .from('bus_live_locations')
          .select('*, buses(*), routes(*), trips(*)')
          .eq('college_id', collegeId);

      return (res as List<dynamic>).map((row) {
        final b = row['buses'] as Map<String, dynamic>? ?? {};
        final r = row['routes'] as Map<String, dynamic>? ?? {};
        final t = row['trips'] as Map<String, dynamic>? ?? {};

        final lat = (row['latitude'] as num?)?.toDouble() ?? 12.9716;
        final lng = (row['longitude'] as num?)?.toDouble() ?? 77.5946;

        return FleetBusLocation(
          bus: Bus(
            id: (b['id'] as String?) ?? '',
            busNumber: (b['bus_number'] as String?) ?? '',
            registrationNumber: b['registration_number'] as String?,
            capacity: b['capacity'] as int?,
          ),
          route: TransportRoute(
            id: (r['id'] as String?) ?? '',
            name: (r['name'] as String?) ?? '',
            stops: const [],
          ),
          activeTrip: t['id'] != null
              ? Trip(
                  id: t['id'] as String,
                  bus: const Bus(id: '', busNumber: ''),
                  route: const TransportRoute(id: '', name: '', stops: []),
                  driver: const DriverProfile(id: '', name: '', phone: ''),
                  stage: TripStage.started,
                )
              : null,
          location: LiveLocation(
            latitude: lat,
            longitude: lng,
            speedKmh: (row['speed'] as num?)?.toDouble(),
            headingDegrees: (row['heading'] as num?)?.toDouble(),
            updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
          ),
          health: DriverDeviceHealth(
            gps: GpsStatus.active,
            network: NetworkStatus.online,
            batteryPercent: 85,
            lastSyncAt: DateTime.now(),
            currentSpeedKmh: (row['speed'] as num?)?.toDouble(),
            currentHeading: (row['heading'] as num?)?.toDouble(),
          ),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<DocumentAlert>> getComplianceAlerts(String collegeId) async {
    try {
      final res = await _client.rpc(
        'get_expiring_documents',
        params: {'p_college_id': collegeId, 'p_days_ahead': 30},
      );

      final list = res is List ? res : (res is Map && res['documents'] is List ? res['documents'] as List : []);

      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final days = (m['days_until_expiry'] as int?) ?? 0;
        final docTypeStr = (m['document_type'] as String?) ?? '';

        final docType = switch (docTypeStr.toLowerCase()) {
          'driver_license' => DocumentType.drivingLicense,
          'rc' => DocumentType.rcBook,
          'insurance' => DocumentType.insurancePolicy,
          'fitness' => DocumentType.fitnessCertificate,
          _ => DocumentType.pucCertificate,
        };

        return DocumentAlert(
          id: (m['id'] as String?) ?? m['document_number'] as String? ?? 'doc-alert',
          collegeId: collegeId,
          entityType: (m['entity_type'] as String?) ?? 'bus',
          entityId: (m['entity_id'] as String?) ?? '',
          entityName: (m['entity_name'] as String?) ?? (m['bus_number'] as String?) ?? 'Fleet Asset',
          documentType: docType,
          documentNumber: (m['document_number'] as String?) ?? (m['registration_number'] as String?) ?? 'N/A',
          expiryDate: DateTime.tryParse(m['expiry_date'] as String? ?? '') ?? DateTime.now().add(Duration(days: days)),
          severity: days < 0 ? ComplianceSeverity.expired : ComplianceSeverity.expiringSoon,
          daysUntilExpiry: days,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  TransportRoute _mapRoute(Map<String, dynamic> routeMap) {
    final rawStops = routeMap['route_stops'] as List<dynamic>? ?? [];
    final stops = rawStops.map((rs) {
      final s = rs['stops'] as Map<String, dynamic>? ?? {};
      return Stop(
        id: (s['id'] as String?) ?? rs['id'].toString(),
        name: (s['name'] as String?) ?? 'Stop',
        latitude: (s['latitude'] as num?)?.toDouble() ?? 12.9716,
        longitude: (s['longitude'] as num?)?.toDouble() ?? 77.5946,
        order: (rs['stop_order'] as int?) ?? 1,
        expectedTime: rs['expected_time'] as String?,
      );
    }).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return TransportRoute(
      id: (routeMap['id'] as String?) ?? 'route-1',
      name: (routeMap['name'] as String?) ?? 'Route',
      stops: stops,
      estimatedDistanceKm: (routeMap['estimated_distance_km'] as num?)?.toDouble(),
    );
  }

  Trip _mapTrip(Map<String, dynamic> json) {
    final busMap = json['buses'] as Map<String, dynamic>? ?? {};
    final routeMap = json['routes'] as Map<String, dynamic>? ?? {};
    final driverMap = json['drivers'] as Map<String, dynamic>? ?? {};
    final driverProfile = driverMap['profiles'] as Map<String, dynamic>? ?? {};

    return Trip(
      id: json['id'] as String,
      bus: Bus(
        id: (busMap['id'] as String?) ?? 'bus-1',
        busNumber: (busMap['bus_number'] as String?) ?? '01',
        registrationNumber: busMap['registration_number'] as String?,
        capacity: (busMap['capacity'] as int?) ?? 40,
      ),
      route: _mapRoute(routeMap),
      driver: DriverProfile(
        id: (driverMap['id'] as String?) ?? 'driver-1',
        name: (driverProfile['full_name'] as String?) ?? 'Driver',
        phone: (driverProfile['phone'] as String?) ?? '',
      ),
      stage: json['status'] == 'active' ? TripStage.started : TripStage.scheduled,
      startedAt: json['actual_start_at'] != null ? DateTime.tryParse(json['actual_start_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String) : null,
    );
  }
}
