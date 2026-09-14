import 'package:flutter/material.dart';

import 'package:localbridge_mobile/features/common/presentation/widgets/download_app_bar_action.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/video_player_body.dart';

/// Fullscreen video player with an optional download action.
///
/// Pass `headers` for a streamed URL, or leave it null to play a local
/// file path.
///
/// Replaces PC Explorer's old `InternalVideoScreen`.
class VideoViewerPage extends StatelessWidget {
  final String title;
  final String source;
  final Map<String, String>? headers;
  final VoidCallback? onDownload;

  const VideoViewerPage({
    super.key,
    required this.title,
    required this.source,
    this.headers,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [DownloadAppBarAction(onDownload: onDownload)],
      ),
      body: VideoPlayerBody(source: source, headers: headers),
    );
  }
}
