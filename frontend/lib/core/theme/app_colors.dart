import 'package:flutter/material.dart';

/// Central color palette for JRapha. Both light and dark themes pull from
/// here so the app has one consistent brand identity across modes.
class AppColors {
  AppColors._();

  // Brand — a calm clinical teal/blue, distinct from generic Material blue
  static const Color primary = Color(0xFF0E7C7B);
  static const Color primaryLight = Color(0xFF4FA8A6);
  static const Color primaryDark = Color(0xFF085958);

  // Accent — warm amber for alerts/highlights (e.g. critical lab results)
  static const Color accent = Color(0xFFE8A33D);

  // Status colors — used consistently across role dashboards
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A33D);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF3B82C4);

  // Light mode surfaces
  static const Color lightBackground = Color(0xFFF7F9F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEDF2F1);
  static const Color lightTextPrimary = Color(0xFF1A2323);
  static const Color lightTextSecondary = Color(0xFF5C6B6A);
  static const Color lightBorder = Color(0xFFDDE5E4);

  // Dark mode surfaces
  static const Color darkBackground = Color(0xFF0F1414);
  static const Color darkSurface = Color(0xFF1A2121);
  static const Color darkSurfaceVariant = Color(0xFF242D2D);
  static const Color darkTextPrimary = Color(0xFFECF2F1);
  static const Color darkTextSecondary = Color(0xFFA3B0AF);
  static const Color darkBorder = Color(0xFF333E3E);
}
