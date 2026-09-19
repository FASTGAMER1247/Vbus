import 'package:flutter/material.dart';

/// Type scale from design.md §6.2. Sizes are the "mobile" column;
/// web/desktop can scale these up later without changing the names
/// screens reference.
class AppTypography {
  AppTypography._();

  static const display = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
  static const title = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
  static const heading = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static const bodySmall =
      TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);

  /// design.md: "Driver primary — 24+ Bold — Driver's essential info
  /// and buttons." Used on the active-trip screen so it stays legible
  /// and tap targets stay large while the driver isn't looking closely.
  static const driverPrimary =
      TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
}

/// Spacing scale from design.md §6.3 (4px grid).
class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  static const screenPaddingMobile = 16.0;
  static const screenPaddingTablet = 24.0;
  static const screenPaddingDesktop = 32.0;
}

/// Corner radii from design.md §6.3.
class AppRadius {
  AppRadius._();
  static const input = 8.0;
  static const card = 12.0;
  static const sheet = 16.0;
}
