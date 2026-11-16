import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/models/transport_models.dart';
import '../../core/models/trip_stage.dart';
import '../repositories/transport_repository.dart';

/// Supabase remote transport repository for student & faculty tracking.
class RemoteTransportRepository implements TransportRepository {
  final sb.SupabaseClient _client;

  RemoteTransportRepository(this._client);

  @override
  Future<EligibilityStatus> getMyEligibility(String userId) async {
    try {
      final response = await _client.rpc(
        'is_student_tracking_eligible',
        params: {'p_student_id': userId},
      );

      final map = response is Map<String, dynamic> ? response : <String, dynamic>{};

      if (map['success'] == true) {
        return EligibilityStatus.eligible;
      }

      final error = map['error'] as String? ?? '';
      switch (error) {
        case 'FEE_PENDING':
        case 'FEE_OVERDUE':
        case 'FEE_NOT_FOUND':
          return EligibilityStatus.feesPending;
        case 'NO_ACTIVE_ASSIGNMENT':
          return EligibilityStatus.routeNotAssigned;
        case 'STUDENT_NOT_FOUND':
        case 'NOT_A_STUDENT':
        case 'STUDENT_NOT_VERIFIED':
          return EligibilityStatus.notEnrolled;
        default:
          return EligibilityStatus.cannotCheckRightNow;
      }
    } catch (_) {
      return EligibilityStatus.cannotCheckRightNow;
    }
  }

  @override
  Future<TransportRoute?> getMyRoute(String userId) async {
    try {
      // Find assignment for student
      final assignment = await _client
          .from('student_transport_assignments')
          .select('route_id, routes(id, name, estimated_distance_km, route_stops(id, stop_order, expected_time, stops(id, name, latitude, longitude)))')
          .eq('student_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (assignment == null) return null;

      final routeMap = assignment['routes'] as Map<String, dynamic>?;
      if (routeMap == null) return null;

      return _mapRoute(routeMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Trip?> getMyActiveTrip(String userId) async {
    try {
      // Get student's assigned bus and route
      final assignment = await _client
          .from('student_transport_assignments')
          .select('route_id, bus_id')
          .eq('student_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (assignment == null) return null;
      final routeId = assignment['route_id'] as String;

      final tripData = await _client
          .from('trips')
          .select('''
            id, status, actual_start_at, completed_at,
            buses(id, bus_number, registration_number, capacity),
            routes(id, name, estimated_distance_km, route_stops(id, stop_order, expected_time, stops(id, name, latitude, longitude))),
            drivers(id, profile_id, driver_code, profiles(full_name, phone)),
            bus_live_locations(latitude, longitude, speed, heading, updated_at)
          ''')
          .eq('route_id', routeId)
          .eq('status', 'active')
          .maybeSingle();

      if (tripData == null) return null;

      final busMap = tripData['buses'] as Map<String, dynamic>? ?? {};
      final routeMap = tripData['routes'] as Map<String, dynamic>? ?? {};
      final driverMap = tripData['drivers'] as Map<String, dynamic>? ?? {};
      final driverProfile = driverMap['profiles'] as Map<String, dynamic>? ?? {};
      final locList = tripData['bus_live_locations'] as List<dynamic>?;
      final locMap = (locList != null && locList.isNotEmpty)
          ? locList.first as Map<String, dynamic>
          : null;

      LiveLocation? lastLoc;
      if (locMap != null) {
        lastLoc = LiveLocation(
          latitude: (locMap['latitude'] as num).toDouble(),
          longitude: (locMap['longitude'] as num).toDouble(),
          speedKmh: (locMap['speed'] as num?)?.toDouble(),
          headingDegrees: (locMap['heading'] as num?)?.toDouble(),
          updatedAt: DateTime.tryParse(locMap['updated_at'] as String) ?? DateTime.now(),
        );
      }

      return Trip(
        id: tripData['id'] as String,
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
        stage: TripStage.started,
        startedAt: tripData['actual_start_at'] != null ? DateTime.tryParse(tripData['actual_start_at'] as String) : null,
        completedAt: tripData['completed_at'] != null ? DateTime.tryParse(tripData['completed_at'] as String) : null,
        lastLocation: lastLoc,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LiveLocation> watchLiveLocation(String tripId) {
    late StreamController<LiveLocation> controller;
    sb.RealtimeChannel? channel;

    controller = StreamController<LiveLocation>.broadcast(
      onListen: () {
        channel = _client.channel('live_bus_locations_$tripId')
          ..onPostgresChanges(
            event: sb.PostgresChangeEvent.all,
            schema: 'public',
            table: 'bus_live_locations',
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty && newRecord['trip_id'] == tripId) {
                final lat = (newRecord['latitude'] as num?)?.toDouble();
                final lng = (newRecord['longitude'] as num?)?.toDouble();
                if (lat != null && lng != null) {
                  controller.add(LiveLocation(
                    latitude: lat,
                    longitude: lng,
                    speedKmh: (newRecord['speed'] as num?)?.toDouble(),
                    headingDegrees: (newRecord['heading'] as num?)?.toDouble(),
                    updatedAt: DateTime.tryParse(newRecord['updated_at'] as String? ?? '') ?? DateTime.now(),
                  ));
                }
              }
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
      name: (routeMap['name'] as String?) ?? 'Campus Route',
      stops: stops,
      estimatedDistanceKm: (routeMap['estimated_distance_km'] as num?)?.toDouble(),
    );
  }
}
