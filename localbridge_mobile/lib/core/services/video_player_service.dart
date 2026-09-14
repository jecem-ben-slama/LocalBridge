import 'package:flutter/widgets.dart';

/// Abstraction over any underlying video-playback engine.
/// Swap the concrete implementation (media_kit, video_player, etc.)
/// without touching any UI or use-case code.
abstract class VideoPlayerService {
  /// Must be called before any other method.
  Future<void> init();

  /// Loads and starts buffering the media at [path].
  /// [path] may be a local file path or a network URL.
  /// [headers] are attached to network requests (e.g. auth tokens)
  /// and ignored when [path] is a local file.
  Future<void> open(String path, {Map<String, String>? headers});

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Returns the widget that actually renders the video surface.
  /// Must only be called after [init].
  Widget buildVideoWidget();

  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;

  bool get isPlaying;

  Future<void> dispose();
}
