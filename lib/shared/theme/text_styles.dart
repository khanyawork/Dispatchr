import 'package:flutter/material.dart';

/// The type scale from README Section 5.4 (12/14/16/20/24/32), applied
/// consistently across every screen rather than ad hoc per-widget sizing.
///
/// Beyond raw sizes, this scale carries the "clean geometric sans-serif"
/// voice the README asks for: large headlines get confident weight (w800)
/// and tight negative tracking so they read as designed display type rather
/// than enlarged body copy; body styles get relaxed line-height for
/// small-screen legibility; and labels pick up a touch of positive
/// letter-spacing for the command-center eyebrow/section-label feel
/// (`RECENT JOBS`, `_SectionLabel`, etc.).
///
/// Colors are intentionally left unset here — [ThemeData] merges this against
/// the color scheme built in `app_theme.dart`, so `textPrimary`/`textSecondary`
/// flow through automatically.
TextTheme buildAppTextTheme() {
  const displayWeight = FontWeight.w800;
  const headingWeight = FontWeight.w700;
  const titleWeight = FontWeight.w600;
  const bodyWeight = FontWeight.w400;
  const labelWeight = FontWeight.w600;

  return const TextTheme(
    // Display/headline — tight tracking, compact leading. Big numbers on
    // the owner dashboard and screen titles should feel engineered.
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: displayWeight,
      letterSpacing: -0.8,
      height: 1.15,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: headingWeight,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: headingWeight,
      letterSpacing: -0.3,
      height: 1.25,
    ),

    // Titles — card headers, list item primaries, AppBar titles.
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: titleWeight,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: titleWeight,
      letterSpacing: -0.1,
      height: 1.35,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: titleWeight,
      letterSpacing: 0,
      height: 1.4,
    ),

    // Body — neutral tracking, generous leading for scanability.
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: bodyWeight,
      letterSpacing: 0.1,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: bodyWeight,
      letterSpacing: 0.1,
      height: 1.45,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: bodyWeight,
      letterSpacing: 0.2,
      height: 1.4,
    ),

    // Labels — buttons, badges, eyebrow/section headers. Slightly open
    // tracking so uppercase micro-labels breathe.
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: labelWeight,
      letterSpacing: 0.3,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: labelWeight,
      letterSpacing: 0.4,
      height: 1.35,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: labelWeight,
      letterSpacing: 0.6,
      height: 1.3,
    ),
  );
}
