import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1A1A2E);
  static const accent = Color(0xFFE94560);
  static const secondary = Color(0xFF16213E);
  static const star = Color(0xFFFFC107);
  static const success = Color(0xFF28A745);

  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E2E)
          : Colors.white;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF0F0F5)
          : const Color(0xFF1A1A2E);

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8A8A9A)
          : const Color(0xFF6C757D);

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF252535)
          : Colors.white;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A3A)
          : const Color(0xFFE9ECEF);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

const String baseUrl = 'http://192.168.18.10:3000/api';