/// flow.md Y1 — Trip lifecycle:
///   SCHEDULED → STARTED → LEAVING COLLEGE → ON ROUTE → FINAL STOPS
///   → RETURNING → APPROACHING COLLEGE → COLLEGE GEOFENCE → COMPLETED
///
/// Backend note (see BACKEND_CHANGES.md): today's backend only exposes
/// 5 statuses (scheduled/active/paused/completed/cancelled). The finer
/// stages here are a UI-level concept for now — either derived from
/// GPS progress client-side, or backfilled once the backend adds a
/// computed stage field. Keeping the full enum here means no screen
/// rewrite is needed either way.
enum TripStage {
  scheduled,
  started,
  leavingCollege,
  onRoute,
  finalStops,
  returning,
  approachingCollege,
  collegeGeofence,
  completed,
  endedManuallyByDriver,
  endedManuallyByManager,
  cancelled;

  bool get isActive => !isTerminal;

  bool get isTerminal =>
      this == TripStage.completed ||
      this == TripStage.endedManuallyByDriver ||
      this == TripStage.endedManuallyByManager ||
      this == TripStage.cancelled;

  String get label {
    switch (this) {
      case TripStage.scheduled:
        return 'Scheduled';
      case TripStage.started:
        return 'Started';
      case TripStage.leavingCollege:
        return 'Leaving college';
      case TripStage.onRoute:
        return 'On route';
      case TripStage.finalStops:
        return 'Final stops';
      case TripStage.returning:
        return 'Returning';
      case TripStage.approachingCollege:
        return 'Approaching college';
      case TripStage.collegeGeofence:
        return 'At college';
      case TripStage.completed:
        return 'Completed';
      case TripStage.endedManuallyByDriver:
      case TripStage.endedManuallyByManager:
        return 'Ended manually';
      case TripStage.cancelled:
        return 'Cancelled';
    }
  }
}
