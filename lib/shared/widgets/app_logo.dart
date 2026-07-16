import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Dispatchr brand mark — a constructed vector monogram, not an icon
/// glyph or image asset, so it renders crisply at any size in both themes.
///
/// Concept: a "D" built from dispatch primitives. The stem and bowl of the
/// letter are drawn as a route stroke; the bowl breaks at its apex for a
/// field-node dot (a job stop on the route), and a hub dot sits inside the
/// counter (the office dispatching the work). Hub → route → node: the
/// product story in one mark.
///
/// The same geometry is hand-authored as a portable SVG at
/// `assets/branding/dispatchr_logo.svg` for use outside the app.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 32, this.color});

  /// Rendered width and height in logical pixels.
  final double size;

  /// Mark color. Defaults to the theme's primary token, so the mark
  /// auto-adapts between light (`#0F766E`) and dark (`#2DD4BF`) themes.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final markColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DispatchrMarkPainter(color: markColor)),
    );
  }
}

/// Paints the Dispatchr "D" monogram on a 100x100 design grid, scaled to
/// the actual canvas size. All geometry mirrors
/// `assets/branding/dispatchr_logo.svg`.
class _DispatchrMarkPainter extends CustomPainter {
  const _DispatchrMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * s
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Stem of the D — a straight route segment.
    canvas.drawLine(Offset(34 * s, 18 * s), Offset(34 * s, 82 * s), stroke);

    // Bowl of the D — a half-circle route (center 34,50 radius 32) broken
    // at its apex (26 degrees either side) to make room for the field node.
    final bowlRect = Rect.fromCircle(
      center: Offset(34 * s, 50 * s),
      radius: 32 * s,
    );
    const gap = 26 * math.pi / 180;
    const quarter = math.pi / 2;
    // Upper arc: from the top of the stem down to the gap.
    canvas.drawArc(bowlRect, -quarter, quarter - gap, false, stroke);
    // Lower arc: from the gap down to the bottom of the stem.
    canvas.drawArc(bowlRect, gap, quarter - gap, false, stroke);

    // Field node — a job stop sitting in the break of the route.
    canvas.drawCircle(Offset(66 * s, 50 * s), 5.5 * s, fill);

    // Hub dot — the dispatch office inside the counter of the D.
    canvas.drawCircle(Offset(48 * s, 50 * s), 5 * s, fill);
  }

  @override
  bool shouldRepaint(_DispatchrMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// The mark paired with the "Dispatchr" wordmark — for the auth screens,
/// the [AppShell] navigation rail header, and an About/branding surface.
class AppWordmark extends StatelessWidget {
  const AppWordmark({
    super.key,
    this.markSize = 28,
    this.color,
    this.textColor,
  });

  /// Size of the logo mark; the wordmark text scales proportionally.
  final double markSize;

  /// Override for the mark color (defaults to the primary token).
  final Color? color;

  /// Override for the wordmark text color (defaults to `textPrimary`
  /// via the theme's `onSurface`).
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: markSize, color: color),
        SizedBox(width: markSize * 0.35),
        Text(
          'Dispatchr',
          style: TextStyle(
            color: textColor ?? theme.colorScheme.onSurface,
            fontSize: markSize * 0.72,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
