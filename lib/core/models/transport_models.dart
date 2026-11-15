import 'dart:math';
import 'trip_stage.dart';

/// prd.md §2 Glossary — "Stop: a pickup or drop point on a route."
class Stop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;
  final String? expectedTime; // e.g. "7:22 AM"

  const Stop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
    this.expectedTime,
  });
}

/// Status of a stop relative to the moving bus during an active trip.
enum StopStage {
  passed,   // Bus has already visited and departed this stop
  atStop,   // Bus is currently dwelling / within stop radius
  next,     // Immediate next destination stop
  upcoming; // Downstream stops scheduled later on route

  String get label {
    switch (this) {
      case StopStage.passed:
        return 'Departed';
      case StopStage.atStop:
        return 'Arriving Now';
      case StopStage.next:
        return 'Next Stop';
      case StopStage.upcoming:
        return 'Upcoming';
    }
  }
}

/// Progress state of an individual stop with calculated dynamic ETA.
class StopProgress {
  final Stop stop;
  final StopStage stage;
  final double distanceMeters;
  final int estimatedMinutes;
  final bool isUserStop;

  const StopProgress({
    required this.stop,
    required this.stage,
    required this.distanceMeters,
    required this.estimatedMinutes,
    this.isUserStop = false,
  });
}

/// Dynamic real-time route progress calculated from live GPS coordinates.
class RouteProgress {
  final Stop? lastStop;
  final Stop nextStop;
  final double distanceToNextStopMeters;
  final int minutesToNextStop;
  final int completedStopsCount;
  final int totalStopsCount;
  final List<StopProgress> allStops;
  final StopProgress? userStopProgress;

  const RouteProgress({
    this.lastStop,
    required this.nextStop,
    required this.distanceToNextStopMeters,
    required this.minutesToNextStop,
    required this.completedStopsCount,
    required this.totalStopsCount,
    required this.allStops,
    this.userStopProgress,
  });

  bool get isUserStopNext => userStopProgress?.stage == StopStage.next;
  bool get isUserStopAtStop => userStopProgress?.stage == StopStage.atStop;
  int get userEtaMinutes => userStopProgress?.estimatedMinutes ?? minutesToNextStop;
}

/// prd.md Module 6 — Routes and Stops.
class TransportRoute {
  final String id;
  final String name; // e.g. "Route 7"
  final List<Stop> stops;
  final double? estimatedDistanceKm;
  final Duration? expectedDuration;

  const TransportRoute({
    required this.id,
    required this.name,
    required this.stops,
    this.estimatedDistanceKm,
    this.expectedDuration,
  });

  /// Calculates dynamic stop-by-stop progress and cumulative ETAs from a live GPS fix.
  RouteProgress calculateProgress({
    required double busLat,
    required double busLng,
    double? speedKmh,
    String? userStopId,
  }) {
    if (stops.isEmpty) {
      throw StateError('Cannot calculate progress for route with no stops');
    }

    // Default urban transit speed fallback (24 km/h = 400 meters/min)
    final effectiveSpeedMpm = (speedKmh != null && speedKmh > 5.0)
        ? (speedKmh * 1000.0 / 60.0)
        : 400.0;

    // 1. Calculate distance from bus to every stop
    final distances = stops.map((s) {
      return _haversineDistance(busLat, busLng, s.latitude, s.longitude);
    }).toList();

    // 2. Identify the active stop index
    // If bus is within 120m of a stop, it is at that stop.
    // Otherwise, find the first upcoming stop that the bus has not yet reached.
    int nextIdx = 0;
    double minUpcomingDist = double.infinity;

    for (var i = 0; i < stops.length; i++) {
      if (distances[i] < minUpcomingDist) {
        minUpcomingDist = distances[i];
        nextIdx = i;
      }
    }

    // Check if within 120m
    final bool isDwellingAtStop = distances[nextIdx] <= 120.0;

    // 3. Build StopProgress items with cumulative ETAs
    final progressList = <StopProgress>[];
    double runningMinutes = 0.0;

    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final dist = distances[i];
      StopStage stage;
      int etaMin;

      if (i < nextIdx) {
        stage = StopStage.passed;
        etaMin = 0;
      } else if (i == nextIdx) {
        stage = isDwellingAtStop ? StopStage.atStop : StopStage.next;
        runningMinutes = isDwellingAtStop ? 1.0 : max(1.0, (dist / effectiveSpeedMpm));
        etaMin = runningMinutes.round();
      } else {
        stage = StopStage.upcoming;
        // Add inter-stop transit time (2-3 minutes average dwell + distance)
        final interStopDist = _haversineDistance(
          stops[i - 1].latitude,
          stops[i - 1].longitude,
          s.latitude,
          s.longitude,
        );
        runningMinutes += max(2.0, (interStopDist / effectiveSpeedMpm) + 1.0); // +1 min dwell
        etaMin = runningMinutes.round();
      }

      progressList.add(StopProgress(
        stop: s,
        stage: stage,
        distanceMeters: dist,
        estimatedMinutes: etaMin,
        isUserStop: s.id == userStopId || (userStopId == null && i == stops.length - 1),
      ));
    }

    final targetNextStop = stops[nextIdx];
    final distToNext = distances[nextIdx];
    final minutesToNext = max(1, (distToNext / effectiveSpeedMpm).round());

    final userProgress = progressList.firstWhere(
      (p) => p.isUserStop,
      orElse: () => progressList.last,
    );

    return RouteProgress(
      lastStop: nextIdx > 0 ? stops[nextIdx - 1] : null,
      nextStop: targetNextStop,
      distanceToNextStopMeters: distToNext,
      minutesToNextStop: minutesToNext,
      completedStopsCount: nextIdx,
      totalStopsCount: stops.length,
      allStops: progressList,
      userStopProgress: userProgress,
    );
  }

  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}

/// prd.md Module 4 — Bus (Fleet) Management, MVP fields only.
class Bus {
  final String id;
  final String busNumber;
  final String? registrationNumber;
  final int? capacity;

  const Bus({
    required this.id,
    required this.busNumber,
    this.registrationNumber,
    this.capacity,
  });
}

/// prd.md Module 5 — Driver Management, MVP fields only.
class DriverProfile {
  final String id;
  final String name;
  final String phone;

  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
  });
}

/// prd.md Module 9 — Live Telemetry coordinate fix.
class LiveLocation {
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final double? headingDegrees;
  final DateTime updatedAt;

  const LiveLocation({
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    this.headingDegrees,
    required this.updatedAt,
  });

  bool isStale({Duration threshold = const Duration(seconds: 30)}) =>
      DateTime.now().difference(updatedAt) > threshold;
}

/// prd.md Module 8 — Trips.
class Trip {
  final String id;
  final TransportRoute route;
  final Bus bus;
  final DriverProfile driver;
  final TripStage stage;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final LiveLocation? lastLocation;

  const Trip({
    required this.id,
    required this.route,
    required this.bus,
    required this.driver,
    required this.stage,
    this.startedAt,
    this.completedAt,
    this.lastLocation,
  });

  Trip copyWith({
    TripStage? stage,
    DateTime? startedAt,
    DateTime? completedAt,
    LiveLocation? lastLocation,
  }) {
    return Trip(
      id: id,
      route: route,
      bus: bus,
      driver: driver,
      stage: stage ?? this.stage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }
}

/// prd.md Module 12 — Eligibility chain.
enum EligibilityStatus {
  eligible,
  notEnrolled,
  feesPending,
  routeNotAssigned,
  cannotCheckRightNow,
}
