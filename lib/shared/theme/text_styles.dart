import 'package:flutter/material.dart';

/// The type scale from README Section 5.4 (12/14/16/20/24/32), applied
/// consistently across every screen rather than ad hoc per-widget sizing.
/// Headings use a bolder weight for the "clean geometric sans-serif" feel;
/// body/label styles stay regular/medium weight for small-screen legibility.
/// Colors are intentionally left unset here — [ThemeData] merges this against
/// the color scheme built in `app_theme.dart`, so `textPrimary`/`textSecondary`
/// flow through automatically.
TextTheme buildAppTextTheme() {
  const headingWeight = FontWeight.w700;
  const titleWeight = FontWeight.w600;
  const bodyWeight = FontWeight.w400;
  const labelWeight = FontWeight.w600;

  return const TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: headingWeight),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: headingWeight),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: headingWeight),
    titleLarge: TextStyle(fontSize: 20, fontWeight: titleWeight),
    titleMedium: TextStyle(fontSize: 16, fontWeight: titleWeight),
    titleSmall: TextStyle(fontSize: 14, fontWeight: titleWeight),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: bodyWeight),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: bodyWeight),
    bodySmall: TextStyle(fontSize: 12, fontWeight: bodyWeight),
    labelLarge: TextStyle(fontSize: 14, fontWeight: labelWeight),
    labelMedium: TextStyle(fontSize: 12, fontWeight: labelWeight),
    labelSmall: TextStyle(fontSize: 12, fontWeight: labelWeight),
  );
}
