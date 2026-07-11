import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shimmer-style loading placeholder used instead of a bare spinner
/// (README Section 5.3) wherever a list of cards is loading — e.g. a
/// technician's job list or a client's request list. A lightened band
/// sweeps across each placeholder bar on a loop.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 84,
    this.padding = const EdgeInsets.all(16),
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  late final Animation<double> _slide = Tween<double>(
    begin: -1.0,
    end: 2.0,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final baseColor = colors.surfaceAlt;
    final highlightColor = _lighten(baseColor, 0.15);

    return AnimatedBuilder(
      animation: _slide,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.3, 0.4],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              tileMode: TileMode.clamp,
              transform: _SlidingGradientTransform(slidePercent: _slide.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: ListView.separated(
        padding: widget.padding,
        itemCount: widget.itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          height: widget.itemHeight,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Lightens [color] by [amount] (0-1) in HSL space — reliably brighter
/// than the base regardless of whether the active theme is light or dark,
/// unlike referencing a fixed second color token.
Color _lighten(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

/// Translates the shimmer gradient horizontally across [bounds] as
/// [slidePercent] runs from -1 to 2, sweeping the highlight band from
/// fully off-screen left to fully off-screen right each loop.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
