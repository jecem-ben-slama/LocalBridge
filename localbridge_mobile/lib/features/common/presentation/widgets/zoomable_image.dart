import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

/// Pinch-to-zoom image body shared by every fullscreen image viewer in the
/// app. PC Explorer's lightbox and the shared-files media viewer used to
/// each hand-roll this same `PhotoView` setup.
class ZoomableImage extends StatelessWidget {
  final ImageProvider imageProvider;
  final Color backgroundColor;

  const ZoomableImage({
    super.key,
    required this.imageProvider,
    this.backgroundColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PhotoView(
      imageProvider: imageProvider,
      backgroundDecoration: BoxDecoration(color: backgroundColor),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      loadingBuilder: (context, event) =>
          Center(child: CircularProgressIndicator(color: colors.primary)),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(Icons.broken_image_rounded, color: colors.muted, size: 48),
      ),
    );
  }
}
