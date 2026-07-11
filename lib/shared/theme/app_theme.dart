import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'text_styles.dart';

/// Builds the app's light/dark [ThemeData] from the design tokens in README
/// Section 5.1, per the split FileManifest.md calls for: `app.dart` only
/// wires up theme *mode* (system/light/dark), while the actual `ThemeData`
/// construction lives here.
ThemeData buildAppTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark
      ? AppColorTokens.dark
      : AppColorTokens.light;

  final colorScheme = ColorScheme(
    brightness: tokens.brightness,
    primary: tokens.primary,
    onPrimary: tokens.onPrimary,
    secondary: tokens.primary,
    onSecondary: tokens.onPrimary,
    error: tokens.alert,
    onError: tokens.onPrimary,
    surface: tokens.surface,
    onSurface: tokens.textPrimary,
    outline: tokens.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: tokens.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.surface,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: buildAppTextTheme(),
    extensions: [
      AppColorExtension(
        primaryHover: tokens.primaryHover,
        surfaceAlt: tokens.surfaceAlt,
        textSecondary: tokens.textSecondary,
        alertHover: tokens.alertHover,
        success: tokens.success,
      ),
    ],
    // Status transitions and button hover/press states (README 5.3) should
    // use this duration wherever a widget animates a color change.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// Semantic colors from README Section 5.1 that don't have a slot in
/// Flutter's [ColorScheme] (hover states, the muted secondary text color,
/// and the dedicated success color for completed-job status).
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.primaryHover,
    required this.surfaceAlt,
    required this.textSecondary,
    required this.alertHover,
    required this.success,
  });

  final Color primaryHover;
  final Color surfaceAlt;
  final Color textSecondary;
  final Color alertHover;
  final Color success;

  @override
  AppColorExtension copyWith({
    Color? primaryHover,
    Color? surfaceAlt,
    Color? textSecondary,
    Color? alertHover,
    Color? success,
  }) {
    return AppColorExtension(
      primaryHover: primaryHover ?? this.primaryHover,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textSecondary: textSecondary ?? this.textSecondary,
      alertHover: alertHover ?? this.alertHover,
      success: success ?? this.success,
    );
  }

  @override
  AppColorExtension lerp(ThemeExtension<AppColorExtension>? other, double t) {
    if (other is! AppColorExtension) return this;
    return AppColorExtension(
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      alertHover: Color.lerp(alertHover, other.alertHover, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
