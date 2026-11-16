import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/providers.dart';
import '../../core/models/transport_models.dart';
import 'permissions_service.dart';

/// State of the driver's phone GPS telemetry stream.
class GpsTrackingStatus {
  final bool isTracking;
  final bool isSimulating;
  final LiveLocation? lastLocation;
  final int packetsSent;
  final String? lastError;

  const GpsTrackingStatus({
    this.isTracking = false,
    this.isSimulating = true,
    this.lastLocation,
    this.packetsSent = 0,
    this.lastError,
  });

  GpsTrackingStatus copyWith({
    bool? isTracking,
    bool? isSimulating,
    LiveLocation? lastLocation,
    int? packetsSent,
    String? lastError,
    bool clearError = false,
  }) {
    return GpsTrackingStatus(
      isTracking: isTracking ?? this.isTracking,
      isSimulating: isSimulating ?? this.isSimulating,
      lastLocation: lastLocation ?? this.lastLocation,
      packetsSent: packetsSent ?? this.packetsSent,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Service that streams driver smartphone GPS coordinates to Supabase Realtime (bus_live_locations).
/// Supports both physical device GPS (via Geolocator) and smooth Route Simulation for testing without moving.
class DriverGpsTrackingNotifier extends StateNotifier<GpsTrackingStatus> {
  final Ref _ref;
  StreamSubscription<Position>? _geolocatorSub;
  Timer? _simulationTimer;
  int _simulationStep = 0;
  List<LiveLocation> _simulatedWaypoints = [];
  Trip? _currentTrip;

  DriverGpsTrackingNotifier(this._ref) : super(const GpsTrackingStatus());

  /// Starts streaming telemetry for the given [trip].
  Future<void> startTracking({
    required Trip trip,
    bool simulate = true,
  }) async {
    stopTracking();
    _currentTrip = trip;
    _simulationStep = 0;

    state = state.copyWith(
      isTracking: true,
      isSimulating: simulate,
      clearError: true,
    );

    if (simulate) {
      _startSimulation(trip);
    } else {
      await _startRealGps(trip);
    }
  }

  /// Stops telemetry streaming and releases location resources.
  void stopTracking() {
    _geolocatorSub?.cancel();
    _geolocatorSub = null;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    state = state.copyWith(isTracking: false);
  }

  /// Toggles between real device GPS and route simulation.
  Future<void> setSimulationMode(bool simulate, Trip trip) async {
    if (state.isSimulating == simulate && state.isTracking) return;
    await startTracking(trip: trip, simulate: simulate);
  }

  void _startSimulation(Trip trip) {
    _simulatedWaypoints = _generateWaypoints(trip.route);
    if (_simulatedWaypoints.isEmpty) return;

    // Send first point immediately
    _emitTelemetryPoint(_simulatedWaypoints.first);

    // Schedule subsequent points every 3 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!state.isTracking || _simulatedWaypoints.isEmpty) {
        timer.cancel();
        return;
      }

      _simulationStep = (_simulationStep + 1) % _simulatedWaypoints.length;
      final point = _simulatedWaypoints[_simulationStep];
      _emitTelemetryPoint(point);
    });
  }

  Future<void> _startRealGps(Trip trip) async {
    final hasPerms = await PermissionsService.requestLocationPermissions();
    if (!hasPerms) {
      state = state.copyWith(
        isTracking: false,
        lastError: 'Location permission required for live GPS tracking.',
      );
      return;
    }

    try {
      DateTime lastEmit = DateTime.now().subtract(const Duration(seconds: 5));

      _geolocatorSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (Position pos) {
          final now = DateTime.now();
          // Rate-limit transmission to max once every 2 seconds (safe for 500ms server check)
          if (now.difference(lastEmit).inMilliseconds < 2000) return;
          lastEmit = now;

          final loc = LiveLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
            speedKmh: pos.speed >= 0 ? pos.speed * 3.6 : 25.0,
            headingDegrees: pos.heading >= 0 ? pos.heading : null,
            updatedAt: now,
          );

          _emitTelemetryPoint(loc);
        },
        onError: (err) {
          state = state.copyWith(lastError: 'GPS error: $err');
        },
      );
    } catch (e) {
      state = state.copyWith(
        isTracking: false,
        lastError: 'Failed to access device GPS: $e',
      );
    }
  }

  Future<void> _emitTelemetryPoint(LiveLocation loc) async {
    if (_currentTrip == null) return;

    try {
      final repo = _ref.read(driverRepositoryProvider);
      final battery = max(15, 88 - (state.packetsSent ~/ 10));

      await repo.recordTelemetry(
        tripId: _currentTrip!.id,
        location: loc,
        batteryPercent: battery,
        networkStatus: 'online',
      );

      if (mounted) {
        state = state.copyWith(
          lastLocation: loc,
          packetsSent: state.packetsSent + 1,
          clearError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(lastError: e.toString());
      }
    }
  }

  /// Generates a smooth sequence of intermediate waypoints along the route stops.
  List<LiveLocation> _generateWaypoints(TransportRoute route) {
    if (route.stops.isEmpty) return const [];
    if (route.stops.length == 1) {
      return [
        LiveLocation(
          latitude: route.stops.first.latitude,
          longitude: route.stops.first.longitude,
          speedKmh: 0,
          headingDegrees: 0,
          updatedAt: DateTime.now(),
        ),
      ];
    }

    final points = <LiveLocation>[];
    const stepsBetweenStops = 4;

    for (var i = 0; i < route.stops.length - 1; i++) {
      final from = route.stops[i];
      final to = route.stops[i + 1];

      final bearing = _calculateBearing(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

      for (var s = 0; s < stepsBetweenStops; s++) {
        final t = s / stepsBetweenStops;
        final lat = from.latitude + (to.latitude - from.latitude) * t;
        final lng = from.longitude + (to.longitude - from.longitude) * t;
        final speed = 24.0 + (s * 3.0);

        points.add(LiveLocation(
          latitude: lat,
          longitude: lng,
          speedKmh: speed,
          headingDegrees: bearing,
          updatedAt: DateTime.now(),
        ));
      }
    }

    // Add final stop
    final last = route.stops.last;
    points.add(LiveLocation(
      latitude: last.latitude,
      longitude: last.longitude,
      speedKmh: 0,
      headingDegrees: 0,
      updatedAt: DateTime.now(),
    ));

    return points;
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final phi1 = lat1 * (pi / 180.0);
    final phi2 = lat2 * (pi / 180.0);

    final y = sin(dLon) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLon);
    final brng = atan2(y, x) * (180.0 / pi);
    return (brng + 360.0) % 360.0;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Provider for managing driver smartphone GPS telemetry streaming.
final driverGpsTrackingProvider =
    StateNotifierProvider<DriverGpsTrackingNotifier, GpsTrackingStatus>((ref) {
  return DriverGpsTrackingNotifier(ref);
});
