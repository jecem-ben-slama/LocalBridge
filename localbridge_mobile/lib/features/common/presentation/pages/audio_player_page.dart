import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/app_loading_indicator.dart';
import 'package:localbridge_mobile/features/common/presentation/widgets/download_app_bar_action.dart';

import '../../../../core/services/video_player_service.dart';
import '../../../../injection_container.dart';
import 'state_placeholder.dart';

/// Plays audio from either a local file path or a network URL.
/// Backed by [VideoPlayerService] since media_kit's Player handles
/// audio-only media the same way as video — just without a video surface.
class AudioPlayerPage extends StatefulWidget {
  final String title;
  final String source;
  final Map<String, String>? headers;
  final VoidCallback? onDownload;

  const AudioPlayerPage({
    super.key,
    required this.title,
    required this.source,
    this.headers,
    this.onDownload,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  VideoPlayerService? _service;
  bool _ready = false;
  bool _failed = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

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

      _playingSub = service.playingStream.listen((playing) {
        if (mounted) setState(() => _playing = playing);
      });
      _positionSub = service.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      });
      _durationSub = service.durationStream.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      });

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
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _service?.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    final service = _service;
    if (service == null) return;
    if (_playing) {
      await service.pause();
    } else {
      await service.play();
    }
  }

  void _seek(Duration position) {
    _service?.seek(position);
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return d.inHours > 0
        ? '${two(d.inHours)}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.darkest,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          DownloadAppBarAction(
            onDownload: widget.onDownload,
            iconColor: colors.text,
          ),
        ],
      ),
      body: Center(child: _buildBody(colors)),
    );
  }

  Widget _buildBody(colors) {
    if (_failed) {
      return StatePlaceholder.inlineError(
        title: "Couldn't play this audio",
        iconColor: colors.error,
      );
    }

    if (!_ready) {
      return const AppLoadingIndicator();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: colors.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.borderSoft,
              thumbColor: colors.primary,
              overlayColor: colors.primary.withValues(alpha: 0.2),
              trackHeight: 3,
            ),
            child: Slider(
              min: 0,
              max: _duration.inMilliseconds > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1,
              value: _position.inMilliseconds
                  .clamp(0, _duration.inMilliseconds)
                  .toDouble(),
              onChanged: (value) =>
                  _seek(Duration(milliseconds: value.round())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            iconSize: 64,
            icon: Icon(
              _playing
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: colors.primary,
            ),
            onPressed: _togglePlay,
          ),
        ],
      ),
    );
  }
}
