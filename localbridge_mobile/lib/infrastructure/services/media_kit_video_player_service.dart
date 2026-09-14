import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/services/video_player_service.dart';

/// media_kit-backed implementation of [VideoPlayerService].
/// This is the ONLY file that should ever import media_kit types.
class MediaKitVideoPlayerService implements VideoPlayerService {
  late final Player _player;
  late final VideoController _controller;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _player = Player();
    _controller = VideoController(_player);
    _initialized = true;
  }

  @override
  Future<void> open(String path, {Map<String, String>? headers}) {
    _assertInitialized();
    return _player.open(Media(path, httpHeaders: headers));
  }

  @override
  Future<void> play() {
    _assertInitialized();
    return _player.play();
  }

  @override
  Future<void> pause() {
    _assertInitialized();
    return _player.pause();
  }

  @override
  Future<void> seek(Duration position) {
    _assertInitialized();
    return _player.seek(position);
  }

  @override
  Widget buildVideoWidget() {
    _assertInitialized();
    return Video(controller: _controller);
  }

  @override
  Stream<bool> get playingStream {
    _assertInitialized();
    return _player.stream.playing;
  }

  @override
  Stream<Duration> get positionStream {
    _assertInitialized();
    return _player.stream.position;
  }

  @override
  Stream<Duration> get durationStream {
    _assertInitialized();
    return _player.stream.duration;
  }

  @override
  bool get isPlaying {
    _assertInitialized();
    return _player.state.playing;
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    await _player.dispose();
    _initialized = false;
  }

  void _assertInitialized() {
    assert(_initialized, 'VideoPlayerService.init() must be called first.');
  }
}
