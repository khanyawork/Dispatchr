import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import 'color_tokens.dart';
import 'text_styles.dart';

/// Builds the app's light/dark [ThemeData] from the design tokens in README
/// Section 5.1, per the split FileManifest.md calls for: `app.dart` only
/// wires up theme *mode* (system/light/dark), while the actual `ThemeData`
/// construction lives here.
///
/// Every component theme below is deliberate — flat borderless app bars with
/// a hairline separation, softly rounded cards defined by a 1px border
/// rather than heavy shadow, consistent 10–12px radii on interactive
/// elements, and hover/press states derived from the `-hover` tokens — so
/// stock Material widgets across all four role surfaces read as one
/// designed system without per-screen styling.
ThemeData buildAppTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark
      ? AppColorTokens.dark
      : AppColorTokens.light;
  final isDark = brightness == Brightness.dark;

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
    outlineVariant: tokens.border,
    surfaceContainerHighest: tokens.surfaceAlt,
    surfaceContainerHigh: tokens.surfaceAlt,
    surfaceContainerLow: tokens.surfaceAlt,
    onSurfaceVariant: tokens.textSecondary,
    surfaceTint: Colors.transparent,
  );

  final textTheme = buildAppTextTheme();

  // Shared geometry — one radius language across the whole app.
  final controlRadius = BorderRadius.circular(10);
  final cardRadius = BorderRadius.circular(14);
  const controlPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

  OutlineInputBorder inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: controlRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Rounded-rect shape shared by the button themes.
  final buttonShape = RoundedRectangleBorder(borderRadius: controlRadius);

  return ThemeData(
    useMaterial3: true,
    brightness: tokens.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.surface,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: textTheme,
    dividerColor: tokens.border,

    // Interaction feedback stays quiet and tinted toward the brand teal
    // rather than Material's default grey splash.
    hoverColor: tokens.primary.withValues(alpha: 0.04),
    focusColor: tokens.primary.withValues(alpha: 0.10),
    highlightColor: tokens.primary.withValues(alpha: 0.06),
    splashColor: tokens.primary.withValues(alpha: 0.08),

    // -----------------------------------------------------------------
    // App bar — flat, borderless, no scroll-under tint shift; a hairline
    // bottom rule provides separation instead of elevation.
    // -----------------------------------------------------------------
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.surface,
      foregroundColor: tokens.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 20,
      shape: Border(bottom: BorderSide(color: tokens.border, width: 1)),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: tokens.textPrimary),
      iconTheme: IconThemeData(color: tokens.textPrimary, size: 22),
      actionsIconTheme: IconThemeData(color: tokens.textSecondary, size: 22),
    ),

    // -----------------------------------------------------------------
    // Cards — definition comes from the hairline border; shadow is a
    // whisper in light mode and absent in dark mode (surfaceAlt fill
    // does the lifting there instead).
    // -----------------------------------------------------------------
    cardTheme: CardThemeData(
      color: isDark ? tokens.surfaceAlt : tokens.surface,
      elevation: isDark ? 0 : 1,
      shadowColor: isDark
          ? Colors.transparent
          : Colors.black.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(color: tokens.border, width: 1),
      ),
    ),

    // -----------------------------------------------------------------
    // Buttons — one radius, one padding rhythm, hover/press resolved to
    // the dedicated `-hover` tokens (README 5.3), motion capped at the
    // hover-transition duration.
    // -----------------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        animationDuration: DesignTokens.hoverTransitionDuration,
        shape: WidgetStatePropertyAll(buttonShape),
        padding: const WidgetStatePropertyAll(controlPadding),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.border;
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return tokens.primaryHover;
          }
          return tokens.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.textSecondary;
          }
          return tokens.onPrimary;
        }),
        overlayColor: WidgetStatePropertyAll(
          tokens.onPrimary.withValues(alpha: 0.04),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        animationDuration: DesignTokens.hoverTransitionDuration,
        shape: WidgetStatePropertyAll(buttonShape),
        padding: const WidgetStatePropertyAll(controlPadding),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(
          isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.18),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.border;
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return tokens.primaryHover;
          }
          return tokens.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.textSecondary;
          }
          return tokens.onPrimary;
        }),
        overlayColor: WidgetStatePropertyAll(
          tokens.onPrimary.withValues(alpha: 0.04),
        ),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (isDark || states.contains(WidgetState.disabled)) return 0;
          if (states.contains(WidgetState.pressed)) return 0;
          if (states.contains(WidgetState.hovered)) return 2;
          return 1;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        animationDuration: DesignTokens.hoverTransitionDuration,
        shape: WidgetStatePropertyAll(buttonShape),
        padding: const WidgetStatePropertyAll(controlPadding),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.textSecondary;
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return tokens.primaryHover;
          }
          return tokens.primary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: tokens.border);
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return BorderSide(color: tokens.primary);
          }
          return BorderSide(color: tokens.border);
        }),
        overlayColor: WidgetStatePropertyAll(
          tokens.primary.withValues(alpha: 0.06),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        animationDuration: DesignTokens.hoverTransitionDuration,
        shape: WidgetStatePropertyAll(buttonShape),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.textSecondary;
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return tokens.primaryHover;
          }
          return tokens.primary;
        }),
        overlayColor: WidgetStatePropertyAll(
          tokens.primary.withValues(alpha: 0.06),
        ),
      ),
    ),

    // -----------------------------------------------------------------
    // Inputs — matches `AppTextField` (filled surfaceAlt, rounded,
    // hairline border, teal focus ring) so bare `TextFormField`s across
    // the app inherit the same look for free.
    // -----------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
      labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
      floatingLabelStyle: textTheme.labelMedium?.copyWith(
        color: tokens.primary,
      ),
      prefixIconColor: tokens.textSecondary,
      suffixIconColor: tokens.textSecondary,
      border: inputBorder(tokens.border),
      enabledBorder: inputBorder(tokens.border),
      focusedBorder: inputBorder(tokens.primary, width: 1.5),
      errorBorder: inputBorder(tokens.alert),
      focusedErrorBorder: inputBorder(tokens.alert, width: 1.5),
      disabledBorder: inputBorder(tokens.border.withValues(alpha: 0.5)),
    ),

    // -----------------------------------------------------------------
    // Supporting components.
    // -----------------------------------------------------------------
    chipTheme: ChipThemeData(
      backgroundColor: tokens.surfaceAlt,
      selectedColor: tokens.primary.withValues(alpha: 0.14),
      checkmarkColor: tokens.primary,
      side: BorderSide(color: tokens.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: tokens.border,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: tokens.textSecondary,
      textColor: tokens.textPrimary,
      titleTextStyle: textTheme.titleSmall?.copyWith(color: tokens.textPrimary),
      subtitleTextStyle: textTheme.bodySmall?.copyWith(
        color: tokens.textSecondary,
      ),
      selectedTileColor: tokens.primary.withValues(alpha: 0.08),
      selectedColor: tokens.primary,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: tokens.surface,
      elevation: 0,
      indicatorColor: tokens.primary.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      selectedIconTheme: IconThemeData(color: tokens.primary, size: 22),
      unselectedIconTheme: IconThemeData(color: tokens.textSecondary, size: 22),
      selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: tokens.primary,
      ),
      unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: tokens.textSecondary,
      ),
      useIndicator: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? tokens.surfaceAlt : tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: isDark ? 0 : 12,
      shadowColor: isDark
          ? Colors.transparent
          : Colors.black.withValues(alpha: 0.20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.border, width: 1),
      ),
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        color: tokens.textPrimary,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: tokens.textSecondary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.textPrimary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.surface),
      actionTextColor: isDark ? tokens.primary : tokens.primaryHover,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: isDark ? 0 : 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tokens.primary,
      linearTrackColor: tokens.surfaceAlt,
      circularTrackColor: Colors.transparent,
    ),
    iconTheme: IconThemeData(color: tokens.textPrimary, size: 22),
    popupMenuTheme: PopupMenuThemeData(
      color: isDark ? tokens.surfaceAlt : tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: isDark ? 0 : 6,
      shadowColor: isDark
          ? Colors.transparent
          : Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.border, width: 1),
      ),
      textStyle: textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.textPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: textTheme.labelMedium?.copyWith(color: tokens.surface),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      waitDuration: const Duration(milliseconds: 400),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tokens.primary,
      foregroundColor: tokens.onPrimary,
      elevation: isDark ? 0 : 3,
      highlightElevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    extensions: [
      AppColorExtension(
        primaryHover: tokens.primaryHover,
        surfaceAlt: tokens.surfaceAlt,
        textSecondary: tokens.textSecondary,
        alertHover: tokens.alertHover,
        success: tokens.success,
        // A barely-there wash from surface into surfaceAlt — ambitious
        // screens (dashboard headers, auth panels) can opt in via
        // `Container(decoration: BoxDecoration(gradient: colors.surfaceGradient))`
        // for a hint of depth without introducing any new color.
        surfaceGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.surface, tokens.surfaceAlt],
        ),
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
/// and the dedicated success color for completed-job status), plus the
/// opt-in [surfaceGradient] branded wash.
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.primaryHover,
    required this.surfaceAlt,
    required this.textSecondary,
    required this.alertHover,
    required this.success,
    required this.surfaceGradient,
  });

  final Color primaryHover;
  final Color surfaceAlt;
  final Color textSecondary;
  final Color alertHover;
  final Color success;

  /// Two-stop `surface → surfaceAlt` diagonal gradient. Deliberately
  /// subtle — a background wash for hero/header regions, never a loud
  /// brand gradient. Screens opt in; nothing forces it.
  final Gradient surfaceGradient;

  @override
  AppColorExtension copyWith({
    Color? primaryHover,
    Color? surfaceAlt,
    Color? textSecondary,
    Color? alertHover,
    Color? success,
    Gradient? surfaceGradient,
  }) {
    return AppColorExtension(
      primaryHover: primaryHover ?? this.primaryHover,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textSecondary: textSecondary ?? this.textSecondary,
      alertHover: alertHover ?? this.alertHover,
      success: success ?? this.success,
      surfaceGradient: surfaceGradient ?? this.surfaceGradient,
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
      surfaceGradient:
          Gradient.lerp(surfaceGradient, other.surfaceGradient, t) ??
          surfaceGradient,
    );
  }
}
