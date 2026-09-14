import 'package:flutter/material.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/download_app_bar_action.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/zoomable_image.dart';

/// Fullscreen pinch-to-zoom image viewer with an optional download action.
///
/// Used by PC Explorer (streamed [NetworkImage] + auth headers). Any other
/// feature that needs a fullscreen image view (e.g. a local [FileImage])
/// can reuse it too.
///
/// Replaces PC Explorer's old private `_ImageLightbox`.
///
/// Note: [onDownload] is no longer expected to pop the route itself —
/// [DownloadAppBarAction] handles that consistently, matching
/// [AudioPlayerPage] and [VideoViewerPage]. Callers that used to call
/// `Navigator.pop()` before invoking their download logic can drop that.
class ImageViewerPage extends StatelessWidget {
  final String title;
  final ImageProvider imageProvider;
  final VoidCallback? onDownload;
  final bool downloadDisabled;

  const ImageViewerPage({
    super.key,
    required this.title,
    required this.imageProvider,
    this.onDownload,
    this.downloadDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          DownloadAppBarAction(
            onDownload: onDownload,
            disabled: downloadDisabled,
          ),
        ],
      ),
      body: ZoomableImage(imageProvider: imageProvider),
    );
  }
}
