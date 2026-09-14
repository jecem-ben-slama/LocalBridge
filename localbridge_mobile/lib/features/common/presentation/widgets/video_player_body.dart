import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/core/services/video_player_service.dart';
import 'package:localbridge_mobile/injection_container.dart';

/// Drives a [VideoPlayerService] for a single video and renders it, with an
/// optional play/pause button.
///
/// Both the shared-files media viewer (local file path, no headers) and PC
/// Explorer's internal video player (streamed URL + auth headers) used to
/// duplicate this init/dispose/play-pause state machine. They now both wrap
/// this one widget and only differ in the `source`/`headers` they pass in.
class VideoPlayerBody extends StatefulWidget {
  final String source;
  final Map<String, String>? headers;
  final bool showPlayPause;

  const VideoPlayerBody({
    super.key,
    required this.source,
    this.headers,
    this.showPlayPause = true,
  });

  @override
  State<VideoPlayerBody> createState() => _VideoPlayerBodyState();
}

class _VideoPlayerBodyState extends State<VideoPlayerBody> {
  VideoPlayerService? _service;
  bool _ready = false;
  bool _failed = false;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final service = locator<VideoPlayerService>();
      await service.init();
      await service.open(widget.source, headers: widget.headers);
      await service.play();
      if (!mounted) return;
      setState(() {
        _service = service;
        _ready = true;
        _playing = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final service = _service;
    if (service == null) return;
    if (_playing) {
      await service.pause();
    } else {
      await service.play();
    }
    if (!mounted) return;
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'Couldn\'t play this video',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (!_ready || _service == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Center(child: _service!.buildVideoWidget()),
        if (widget.showPlayPause)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FloatingActionButton(
              heroTag: null,
              backgroundColor: colors.primary,
              onPressed: _togglePlay,
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: colors.darkest,
              ),
            ),
          ),
      ],
    );
  }
}
