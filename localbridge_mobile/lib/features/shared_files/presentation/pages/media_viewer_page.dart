import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/video_player_body.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/zoomable_image.dart';

import '../../domain/entities/shared_file.dart';

/// Fullscreen viewer for a locally-saved shared image or video.
///
/// The image/video bodies are shared with PC Explorer via [ZoomableImage]
/// and [VideoPlayerBody]; this page just supplies the themed gradient
/// AppBar chrome specific to the Recently Shared flow.
class MediaViewerPage extends StatelessWidget {
  final SharedFile file;
  final bool isVideo;

  const MediaViewerPage({super.key, required this.file, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.darkest,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.darkest.withValues(alpha: 0.9),
                colors.darkest.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: colors.text),
            title: Text(
              file.name,
              style: TextStyle(
                color: colors.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body: isVideo
          ? VideoPlayerBody(source: file.path)
          : ZoomableImage(
              imageProvider: FileImage(File(file.path)),
              backgroundColor: colors.darkest,
            ),
    );
  }
}
