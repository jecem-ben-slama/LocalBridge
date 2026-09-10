import 'package:flutter/material.dart';

abstract class AppColors {
  const AppColors._();

  // Backgrounds
  static const Color darkest = Color(0xFF070B14);
  static const Color dark = Color(0xFF0B1120);
  static const Color card = Color(0xFF111827);
  static const Color elevated = Color(0xFF172033);

  // Borders
  static const Color border = Color(0xFF243047);
  static const Color borderSoft = Color(0xFF1A2436);
  static const Color borderStrong = Color(0xFF334155);

  // Primary — Teal
  static const Color primary = Color(0xFF14B8A6);
  static const Color primaryHover = Color(0xFF0D9488);
  static const Color primaryActive = Color(0xFF0F766E);
  static const Color primarySoft = Color(0xFF0F3D3A);

  // Secondary Accent — Cyan
  static const Color accent = Color(0xFF22D3EE);
  static const Color accentSoft = Color(0xFF1E5A73);

  // Text
  static const Color text = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color muted = Color(0xFF94A3B8);
  static const Color mutedDark = Color(0xFF64748B);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0x2922C55E); // 16% opacity

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0x29F59E0B); // 16% opacity

  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0x29EF4444); // 16% opacity

  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0x293B82F6); // 16% opacity
}
