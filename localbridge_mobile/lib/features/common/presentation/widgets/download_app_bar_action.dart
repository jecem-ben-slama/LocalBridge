import 'package:flutter/material.dart';

/// A single "download" action for a fullscreen viewer's AppBar.
///
/// Previously each viewer reimplemented this independently, and
/// inconsistently:
///  - [AudioPlayerPage] and [VideoViewerPage] popped the route themselves
///    before invoking `onDownload`.
///  - [ImageViewerPage] did *not* pop internally, leaving it up to whoever
///    constructed the callback (PC Explorer) to remember to pop first.
///
/// This widget always pops first (configurable), so every caller gets the
/// same behavior for free and no longer needs to think about it.
class DownloadAppBarAction extends StatelessWidget {
  final VoidCallback? onDownload;
  final bool popBeforeDownload;
  final Color iconColor;
  final bool disabled;

  const DownloadAppBarAction({
    super.key,
    required this.onDownload,
    this.popBeforeDownload = true,
    this.iconColor = Colors.white,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onDownload == null) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'Download',
      icon: Icon(Icons.download_rounded, color: iconColor),
      onPressed: disabled
          ? null
          : () {
              if (popBeforeDownload) Navigator.of(context).pop();
              onDownload!();
            },
    );
  }
}
