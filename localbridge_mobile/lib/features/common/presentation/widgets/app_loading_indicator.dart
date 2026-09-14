import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

/// Centered circular spinner using the app's primary color.
///
/// Replaces the repeated `Center(child: CircularProgressIndicator(color:
/// colors.primary))` that appeared identically in PC Explorer, Recently
/// Shared, the audio player, and the text file viewer.
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.size = 36,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: colors.primary,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
