import 'package:flutter/material.dart';

/// Raw design tokens for Dispatchr, mirroring README.md Section 5
/// ("Design System Specification"). This is the single source of truth for
/// color, typography, and motion primitives — widgets and `ThemeData` should
/// reference these constants rather than hardcoding hex values or durations.
class DesignTokens {
  DesignTokens._();

  // ---------------------------------------------------------------------
  // 5.1 Color Palette — Light Mode
  // ---------------------------------------------------------------------
  static const Color primaryLight = Color(0xFF0F766E);
  static const Color primaryHoverLight = Color(0xFF0D5F58);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFF4F5F6);
  static const Color borderLight = Color(0xFFD8DCDE);
  static const Color textPrimaryLight = Color(0xFF1A1D1F);
  static const Color textSecondaryLight = Color(0xFF5B6166);
  static const Color alertLight = Color(0xFFDC2626);
  static const Color alertHoverLight = Color(0xFFB91C1C);
  static const Color successLight = Color(0xFF16A34A);

  // ---------------------------------------------------------------------
  // 5.1 Color Palette — Dark Mode
  // ---------------------------------------------------------------------
  static const Color primaryDark = Color(0xFF2DD4BF);
  static const Color primaryHoverDark = Color(0xFF5EEAD4);
  static const Color surfaceDark = Color(0xFF121417);
  static const Color surfaceAltDark = Color(0xFF1B1E22);
  static const Color borderDark = Color(0xFF2A2E33);
  static const Color textPrimaryDark = Color(0xFFF2F3F4);
  static const Color textSecondaryDark = Color(0xFFA0A6AB);
  static const Color alertDark = Color(0xFFF87171);
  static const Color alertHoverDark = Color(0xFFFCA5A5);
  static const Color successDark = Color(0xFF4ADE80);

  // ---------------------------------------------------------------------
  // 5.4 Typography — type scale (logical pixels)
  // ---------------------------------------------------------------------
  static const double fontSizeXs = 12;
  static const double fontSizeSm = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 20;
  static const double fontSizeXl = 24;
  static const double fontSizeXxl = 32;

  // ---------------------------------------------------------------------
  // 5.3 Interaction States — motion & timing
  // ---------------------------------------------------------------------
  /// Hover/press color transition for buttons and other interactive elements.
  static const Duration hoverTransitionDuration = Duration(milliseconds: 180);

  /// Status badge color/label transition (e.g. Pending → In Progress).
  static const Duration statusTransitionDuration = Duration(milliseconds: 200);

  /// Upper bound for any micro-animation so motion reads as responsive,
  /// not decorative.
  static const Duration maxMotionDuration = Duration(milliseconds: 250);

  /// Scale applied to cards/buttons on hover to reinforce interactivity.
  static const double hoverScale = 1.02;
}
