import 'package:flutter/material.dart';

/// Raw hex values from README Section 5.1 ("Design System Specification") —
/// teal/grey/white/red tokens for light and dark mode. [buildAppTheme] in
/// `app_theme.dart` is the only place that should read from this directly.
class AppColorTokens {
  const AppColorTokens({
    required this.brightness,
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.alert,
    required this.alertHover,
    required this.success,
  });

  final Brightness brightness;
  final Color primary;
  final Color primaryHover;
  final Color onPrimary;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color alert;
  final Color alertHover;
  final Color success;

  static const light = AppColorTokens(
    brightness: Brightness.light,
    primary: Color(0xFF0F766E),
    primaryHover: Color(0xFF0D5F58),
    onPrimary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF4F5F6),
    border: Color(0xFFD8DCDE),
    textPrimary: Color(0xFF1A1D1F),
    textSecondary: Color(0xFF5B6166),
    alert: Color(0xFFDC2626),
    alertHover: Color(0xFFB91C1C),
    success: Color(0xFF16A34A),
  );

  static const dark = AppColorTokens(
    brightness: Brightness.dark,
    primary: Color(0xFF2DD4BF),
    primaryHover: Color(0xFF5EEAD4),
    onPrimary: Color(0xFF121417),
    surface: Color(0xFF121417),
    surfaceAlt: Color(0xFF1B1E22),
    border: Color(0xFF2A2E33),
    textPrimary: Color(0xFFF2F3F4),
    textSecondary: Color(0xFFA0A6AB),
    alert: Color(0xFFF87171),
    alertHover: Color(0xFFFCA5A5),
    success: Color(0xFF4ADE80),
  );
}
