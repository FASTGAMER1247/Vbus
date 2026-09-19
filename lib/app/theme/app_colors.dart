import 'package:flutter/material.dart';
import '../../core/models/role.dart';

/// Colors from design.md §3 (Role Identity) and §6.1 (Colors).
/// Everything here is still "Proposed" per that doc — change freely,
/// this file is the single place that needs editing.
class AppColors {
  AppColors._();

  // ---- Neutrals (shared by every role) ----
  static const lightBackground = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE0E3E8);
  static const lightTextPrimary = Color(0xFF1F2328);
  static const lightTextSecondary = Color(0xFF5F6672);
  static const lightTextDisabled = Color(0xFF9AA0A6);

  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkBorder = Color(0xFF333333);
  static const darkTextPrimary = Color(0xFFF1F3F4);
  static const darkTextSecondary = Color(0xFFA8AFB8);
  static const darkTextDisabled = Color(0xFF6B7078);

  // ---- Role accents (design.md §3) ----
  static const masterAdminAccent = Color(0xFFD93025); // red
  static const managerAccent = Color(0xFFF57C00); // orange
  static const studentAccent = Color(0xFF1E8E3E); // green
  static const facultyAccent = Color(0xFF7B3FBF); // purple
  static const driverAccent = Color(0xFF1A73E8); // blue

  static Color accentFor(UserRole role) {
    switch (role) {
      case UserRole.masterAdmin:
        return masterAdminAccent;
      case UserRole.manager:
        return managerAccent;
      case UserRole.student:
        return studentAccent;
      case UserRole.faculty:
        return facultyAccent;
      case UserRole.driver:
        return driverAccent;
    }
  }

  // ---- Status colors (same in every role — never role-dependent) ----
  static const statusGood = Color(0xFF1E8E3E); // online / active
  static const statusWarning = Color(0xFFF9AB00); // weak / low battery
  static const statusCritical = Color(0xFFD93025); // error / emergency
  static const statusUnavailable = Color(0xFF80868B); // offline / inactive
  static const statusInfo = Color(0xFF1A73E8);
}
