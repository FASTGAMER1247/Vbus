import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/models/compliance_models.dart';
import '../../core/models/driver_models.dart';
import '../../core/models/transport_models.dart';
import '../../core/models/trip_stage.dart';
import '../repositories/driver_repository.dart';

/// Supabase remote driver repository calling live PL/pgSQL RPCs and Realtime streams.
class RemoteDriverRepository implements DriverRepository {
  final sb.SupabaseClient _client;
  final _locationController = StreamController<LiveLocation>.broadcast();
  final _healthController = StreamController<DriverDeviceHealth>.broadcast();

  String? _currentTrackingSessionId;

  RemoteDriverRepository(this._client);

  @override
  Future<Trip?> getTodayScheduledTrip(String driverId) async {
    try {
      final driverRecord = await _client
          .from('drivers')
          .select('id')
          .or('profile_id.eq.$driverId,id.eq.$driverId')
          .maybeSingle();

      if (driverRecord == null) return null;
      final internalDriverId = driverRecord['id'] as String;

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final tripData = await _client
          .from('trips')
          .select('''
            id, status, scheduled_date, scheduled_departure_time, actual_start_at,
            buses(id, bus_number, registration_number, capacity),
            routes(id, name, estimated_distance_km, route_stops(id, stop_order, expected_time, stops(id, name, latitude, longitude))),
            drivers(id, profile_id, driver_code, profiles(full_name, phone))
          ''')
          .eq('driver_id', internalDriverId)
          .eq('scheduled_date', today)
          .inFilter('status', ['scheduled', 'active', 'paused'])
          .order('scheduled_departure_time')
          .limit(1)
          .maybeSingle();

      if (tripData == null) return null;
      return _mapTrip(tripData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DriverScanResult> identifyBus({
    required String driverId,
    required String busIdOrCode,
  }) async {
    try {
      final response = await _client.rpc(
        'start_trip_by_bus',
        params: {'p_qr_code': busIdOrCode.trim()},
      );

      final map = response is Map<String, dynamic> ? response : <String, dynamic>{};

      if (map['success'] != true) {
        final errorCode = map['error'] as String? ?? 'UNKNOWN';
        _handleRpcError(errorCode, map['message'] as String?);
      }

      final tripJson = map['trip'] as Map<String, dynamic>?;
      _currentTrackingSessionId = map['tracking_session_id'] as String?;

      if (tripJson == null) {
        throw const DriverBlockedException(DriverBlockReason.busNotFound);
      }

      final trip = _mapTrip(tripJson);
      return DriverScanResult(
        trip: trip,
        isUnassignedTakeover: map['is_unassigned_takeover'] == true,
      );
    } on DriverBlockedException {
      rethrow;
    } catch (e) {
      throw const DriverBlockedException(
        DriverBlockReason.busNotFound,
        documentAlert: null,
      );
    }
  }

  void _handleRpcError(String code, String? message) {
    switch (code) {
      case 'BUS_NOT_FOUND':
      case 'INVALID_QR_CODE':
        throw const DriverBlockedException(DriverBlockReason.busNotFound);
      case 'TENANT_MISMATCH':
        throw const DriverBlockedException(DriverBlockReason.busAnotherCollege);
      case 'BUS_ALREADY_IN_TRIP':
        throw const DriverBlockedException(DriverBlockReason.busAlreadyActive);
      case 'DRIVER_NOT_ASSIGNED':
        throw const DriverBlockedException(DriverBlockReason.busNotAssignedToDriver);
      case 'LICENSE_EXPIRED':
        throw DriverBlockedException(
          DriverBlockReason.driverLicenseExpired,
          documentAlert: DocumentAlert(
            id: 'dl-alert-expired',
            collegeId: '',
            entityType: 'driver',
            entityId: '',
            entityName: 'Driver Commercial License',
            documentType: DocumentType.drivingLicense,
            documentNumber: 'DL-EXPIRED',
            expiryDate: DateTime.now().subtract(const Duration(days: 1)),
            severity: ComplianceSeverity.expired,
            daysUntilExpiry: -1,
          ),
        );
      case 'BUS_DOCUMENT_EXPIRED':
      case 'BUS_INACTIVE':
        throw DriverBlockedException(
          DriverBlockReason.busDocumentExpired,
          documentAlert: DocumentAlert(
            id: 'puc-alert-expired',
            collegeId: '',
            entityType: 'bus',
            entityId: '',
            entityName: 'Bus Fitness / PUC Certificate',
            documentType: DocumentType.pucCertificate,
            documentNumber: 'PUC-EXPIRED',
            expiryDate: DateTime.now().subtract(const Duration(days: 1)),
            severity: ComplianceSeverity.expired,
            daysUntilExpiry: -1,
          ),
        );
      default:
        throw const DriverBlockedException(DriverBlockReason.busNotFound);
    }
  }

  @override
  Future<Trip> startTrip(String tripId) async {
    final response = await _client.rpc('start_trip', params: {'p_trip_id': tripId});
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    _currentTrackingSessionId = map['tracking_session_id'] as String?;

    try {
      final sess = await _client.rpc('start_tracking_session', params: {'p_trip_id': tripId});
      if (sess is Map && sess['tracking_session_id'] != null) {
        _currentTrackingSessionId = sess['tracking_session_id'] as String;
      }
    } catch (_) {}

    final tripData = await _client
        .from('trips')
        .select('''
          id, status, scheduled_date, scheduled_departure_time, actual_start_at,
          buses(id, bus_number, registration_number, capacity),
          routes(id, name, estimated_distance_km, route_stops(id, stop_order, expected_time, stops(id, name, latitude, longitude))),
          drivers(id, profile_id, driver_code, profiles(full_name, phone))
        ''')
        .eq('id', tripId)
        .single();

    return _mapTrip(tripData);
  }

  @override
  Future<Trip> endTripManually(String tripId, {required bool insideGeofence}) async {
    if (_currentTrackingSessionId != null) {
      try {
        await _client.rpc('end_tracking_session', params: {'p_session_id': _currentTrackingSessionId!});
      } catch (_) {}
    }

    await _client.rpc('complete_trip', params: {
      'p_trip_id': tripId,
      'p_end_reason': insideGeofence ? 'arrived_campus' : 'driver_manual',
    });

    final tripData = await _client
        .from('trips')
        .select('''
          id, status, scheduled_date, scheduled_departure_time, actual_start_at, completed_at,
          buses(id, bus_number, registration_number, capacity),
          routes(id, name, estimated_distance_km, route_stops(id, stop_order, expected_time, stops(id, name, latitude, longitude))),
          drivers(id, profile_id, driver_code, profiles(full_name, phone))
        ''')
        .eq('id', tripId)
        .single();

    _currentTrackingSessionId = null;
    return _mapTrip(tripData);
  }

  @override
  Stream<DriverDeviceHealth> watchDeviceHealth() => _healthController.stream;

  @override
  Stream<LiveLocation> watchDriverLocation() => _locationController.stream;

  @override
  Future<void> recordTelemetry({
    required String tripId,
    required LiveLocation location,
    int? batteryPercent,
    String? networkStatus,
  }) async {
    _locationController.add(location);
    final now = location.updatedAt;

    _healthController.add(DriverDeviceHealth(
      gps: GpsStatus.active,
      network: networkStatus == 'offline' ? NetworkStatus.offline : NetworkStatus.online,
      batteryPercent: batteryPercent ?? 85,
      lastSyncAt: now,
      currentSpeedKmh: location.speedKmh,
      currentHeading: location.headingDegrees,
    ));

    // Resolve active tracking session if not already cached
    if (_currentTrackingSessionId == null) {
      try {
        final sess = await _client
            .from('tracking_sessions')
            .select('id')
            .eq('trip_id', tripId)
            .eq('status', 'active')
            .maybeSingle();
        if (sess != null) {
          _currentTrackingSessionId = sess['id'] as String;
        }
      } catch (_) {}
    }

    if (_currentTrackingSessionId != null) {
      try {
        await _client.rpc('record_tracking_location', params: {
          'p_tracking_session_id': _currentTrackingSessionId,
          'p_latitude': location.latitude,
          'p_longitude': location.longitude,
          'p_speed': location.speedKmh,
          'p_heading': location.headingDegrees,
          'p_accuracy': 5.0,
          'p_altitude': 0.0,
          'p_recorded_at': now.toIso8601String(),
          'p_source': 'driver_phone',
          'p_battery_percentage': batteryPercent ?? 85,
          'p_network_status': networkStatus ?? 'online',
        });
      } catch (_) {}
    }
  }

  Future<void> recordGpsPoint({
    required double latitude,
    required double longitude,
    double? speedKmh,
    double? heading,
    int? batteryPercent,
    String? networkStatus,
  }) async {
    final now = DateTime.now();
    await recordTelemetry(
      tripId: '',
      location: LiveLocation(
        latitude: latitude,
        longitude: longitude,
        speedKmh: speedKmh,
        headingDegrees: heading,
        updatedAt: now,
      ),
      batteryPercent: batteryPercent,
      networkStatus: networkStatus,
    );
  }

  Trip _mapTrip(Map<String, dynamic> json) {
    final busMap = json['buses'] as Map<String, dynamic>? ?? {};
    final routeMap = json['routes'] as Map<String, dynamic>? ?? {};
    final driverMap = json['drivers'] as Map<String, dynamic>? ?? {};
    final driverProfile = driverMap['profiles'] as Map<String, dynamic>? ?? {};

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

    final rawStatus = (json['status'] as String?) ?? 'scheduled';
    final stage = switch (rawStatus) {
      'active' => TripStage.started,
      'completed' => TripStage.completed,
      'cancelled' => TripStage.cancelled,
      _ => TripStage.scheduled,
    };

    return Trip(
      id: json['id'] as String,
      bus: Bus(
        id: (busMap['id'] as String?) ?? 'bus-1',
        busNumber: (busMap['bus_number'] as String?) ?? '01',
        registrationNumber: busMap['registration_number'] as String?,
        capacity: (busMap['capacity'] as int?) ?? 40,
      ),
      route: TransportRoute(
        id: (routeMap['id'] as String?) ?? 'route-1',
        name: (routeMap['name'] as String?) ?? 'Route 1',
        stops: stops,
        estimatedDistanceKm: (routeMap['estimated_distance_km'] as num?)?.toDouble(),
      ),
      driver: DriverProfile(
        id: (driverMap['id'] as String?) ?? 'driver-1',
        name: (driverProfile['full_name'] as String?) ?? 'Driver',
        phone: (driverProfile['phone'] as String?) ?? '',
      ),
      stage: stage,
      startedAt: json['actual_start_at'] != null ? DateTime.tryParse(json['actual_start_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String) : null,
    );
  }
}
