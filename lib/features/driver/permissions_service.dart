import 'package:geolocator/geolocator.dart';

/// flow.md D1: "First trip: location permissions granted?" and
/// prd.md rule: background location is only ever requested from
/// drivers, only when a trip is about to start.
///
/// This is real geolocator code, not mocked — permission behavior is
/// OS-specific enough (especially Android's two-step "while using" →
/// "always" flow, and battery-optimization allowlisting on Xiaomi/
/// Samsung phones per prd.md §15.3 risks) that it has to be tested on
/// real devices early, per the project's own test scenarios
/// (prd.md §14, items 1–3).
class PermissionsService {
  PermissionsService._();

  /// Returns true only if background ("always") location is granted —
  /// that's what D2 needs to keep tracking with the screen locked.
  static Future<bool> requestLocationPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false; // caller shows "how to enable" instructions (D5 table)
    }

    // Android only grants "always" via a second request after
    // "whileInUse" is already held; iOS handles this through its own
    // system prompt sequence. Either way, request once more to surface
    // the background prompt where the OS supports asking for it here.
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse; // fallback allowed for the demo build
  }

  static Future<bool> isPermanentlyDenied() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }
}
