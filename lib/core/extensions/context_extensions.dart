import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// `BuildContext` convenience extensions for Dispatchr, per `FileManifest.md`
/// (`lib/core/extensions/context_extensions.dart`). Wraps `Theme.of`,
/// `MediaQuery.of`, and `Navigator.of` boilerplate, and standardizes
/// success/error feedback using the tokens in `design_tokens.dart` so
/// screens across all four roles stay visually consistent (README
/// Section 5) without importing `DesignTokens` everywhere directly.
extension ContextExtensions on BuildContext {
  // ---------------------------------------------------------------------
  // Theme shortcuts
  // ---------------------------------------------------------------------

  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ---------------------------------------------------------------------
  // Layout / responsiveness — relevant since Dispatchr targets phones
  // (client/technician) and desktop window sizes (owner command center)
  // ---------------------------------------------------------------------

  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Below this width, use single-column/mobile layouts.
  static const double _mobileBreakpoint = 600;

  /// Below this width (but at/above the mobile breakpoint), use a
  /// tablet/split layout; at or above it, use the desktop command-center
  /// layout (owner/admin screens).
  static const double _desktopBreakpoint = 1024;

  bool get isMobile => screenWidth < _mobileBreakpoint;

  bool get isTablet =>
      screenWidth >= _mobileBreakpoint && screenWidth < _desktopBreakpoint;

  bool get isDesktop => screenWidth >= _desktopBreakpoint;

  // ---------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------

  NavigatorState get navigator => Navigator.of(this);

  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  // ---------------------------------------------------------------------
  // Feedback — colored per README Section 5.1 (red reserved for
  // destructive/error states, green for success/completion)
  // ---------------------------------------------------------------------

  void showSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showErrorSnackBar(String message) {
    final color = isDarkMode ? DesignTokens.alertDark : DesignTokens.alertLight;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }

  void showSuccessSnackBar(String message) {
    final color =
        isDarkMode ? DesignTokens.successDark : DesignTokens.successLight;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }

  // ---------------------------------------------------------------------
  // Keyboard
  // ---------------------------------------------------------------------

  /// Dismisses the on-screen keyboard, e.g. after submitting a form.
  void unfocus() => FocusScope.of(this).unfocus();
}
