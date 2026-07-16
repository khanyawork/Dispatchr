import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';

/// Primary call-to-action button with hover/press states per README
/// Section 5.3: a 150–200ms ease-out color transition to the `-hover`
/// token on hover (desktop/web) or press (mobile), plus a subtle ~1.02x
/// scale on hover to reinforce interactivity — no instant color snaps,
/// and motion stays under the 250ms ceiling. `FileManifest.md`:
/// `lib/shared/widgets/primary_button.dart`.
///
/// Visual notes: enabled buttons carry a faint teal-tinted drop shadow in
/// light mode (deepening slightly on hover) so the CTA sits just above the
/// page; in dark mode the bright teal fill provides all the emphasis and
/// shadows stay off. Press compresses to 0.98x for a tactile response.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final base = isDark ? DesignTokens.primaryDark : DesignTokens.primaryLight;
    final hover = isDark
        ? DesignTokens.primaryHoverDark
        : DesignTokens.primaryHoverLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textSecondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondaryLight;
    // Ink on the teal fill: white in light mode, near-black in dark mode
    // (where the primary teal is bright).
    final onPrimary = context.colorScheme.onPrimary;

    final isActive = _isHovered || _isPressed;
    final backgroundColor = _isDisabled ? border : (isActive ? hover : base);
    final foregroundColor = _isDisabled ? textSecondary : onPrimary;
    final scale = _isDisabled
        ? 1.0
        : _isPressed
        ? 0.98
        : (_isHovered ? DesignTokens.hoverScale : 1.0);

    // A whisper of teal-tinted depth under the CTA — light mode only;
    // dark mode relies on the bright fill for emphasis.
    final shadows = (_isDisabled || isDark)
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: base.withValues(alpha: _isHovered ? 0.30 : 0.18),
              blurRadius: _isHovered ? 14 : 8,
              offset: Offset(0, _isHovered ? 5 : 3),
            ),
          ];

    return MouseRegion(
      cursor: _isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: _isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: _isDisabled
            ? null
            : () => setState(() => _isPressed = false),
        onTap: _isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: DesignTokens.hoverTransitionDuration,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: DesignTokens.hoverTransitionDuration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: shadows,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.isLoading
                  ? [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: onPrimary,
                        ),
                      ),
                    ]
                  : [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: foregroundColor, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: DesignTokens.fontSizeMd,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
