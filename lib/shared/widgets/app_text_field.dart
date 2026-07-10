import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';

/// Consistent text field styling sourced from `design_tokens.dart` —
/// border/focus/error colors — rather than hardcoded per screen (README
/// Section 5: "no hardcoded colors"). `FileManifest.md`:
/// `lib/shared/widgets/app_text_field.dart`.
///
/// Focus/error border color transitions are handled by Flutter's built-in
/// `InputDecorator` animation, which already runs close to the 150–200ms
/// window called for in README Section 5.3.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.autofocus = false,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final IconData? prefixIcon;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final primary = isDark
        ? DesignTokens.primaryDark
        : DesignTokens.primaryLight;
    final alert = isDark ? DesignTokens.alertDark : DesignTokens.alertLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    final surfaceAlt = isDark
        ? DesignTokens.surfaceAltDark
        : DesignTokens.surfaceAltLight;

    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: textSecondary),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: textSecondary),
        filled: true,
        fillColor: surfaceAlt,
        border: outline(border),
        enabledBorder: outline(border),
        focusedBorder: outline(primary),
        errorBorder: outline(alert),
        focusedErrorBorder: outline(alert),
      ),
    );
  }
}
