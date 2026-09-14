import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

/// Wraps [child] with a single horizontal shimmer sweep.
///
/// Wrap this around a whole list/grid of skeleton tiles rather than around
/// each tile individually — one [AnimationController] driving a shader mask
/// over the full skeleton area is far cheaper than one per tile, and keeps
/// every tile's sweep in sync.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                colors.borderSoft,
                colors.borderStrong,
                colors.borderSoft,
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-1 - 2 * t, 0),
              end: Alignment(1 - 2 * t, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
