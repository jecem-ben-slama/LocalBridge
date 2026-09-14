import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

/// A plain rounded placeholder rectangle. The building block every skeleton
/// tile (grid tile, list tile, shared file tile) is composed from, so a
/// single spot controls the base color/shape used by every "loading" state.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = const BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.borderSoft,
        borderRadius: borderRadius,
      ),
    );
  }
}
