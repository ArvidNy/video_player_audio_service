import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

class VideoPlayerHandler extends BaseAudioHandler with SeekHandler {
  static final _item = MediaItem(
    id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    album: "Science Friday",
    title: "A Salute To Head-Scratching Science",
    artist: "Science Friday and WNYC Studios",
    duration: const Duration(milliseconds: 5739820),
    artUri: Uri.parse(
      'https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg',
    ),
  );

  VideoPlayerController? _player;
  final _playerController = BehaviorSubject<VideoPlayerController?>();
  AudioSession? _session;

  Stream<VideoPlayerController?> get playerController =>
      _playerController.stream;

  VideoPlayerHandler() {
    mediaItem.add(_item);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _player = VideoPlayerController.networkUrl(
      Uri.parse(_item.id),
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
    );
    await _player!.initialize();
    _playerController.add(_player);
    _player!.addListener(_broadcastState);
    mediaItem.add(_item.copyWith(duration: _player!.value.duration));
    _broadcastState();
    _session = await AudioSession.instance;
    await _session?.configure(AudioSessionConfiguration.speech());
  }

  void _broadcastState() {
    if (_player == null) return;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.rewind,
          _player!.value.isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        processingState:
            _player!.value.isInitialized
                ? (_player!.value.position >= _player!.value.duration
                    ? AudioProcessingState.completed
                    : AudioProcessingState.ready)
                : AudioProcessingState.loading,
        playing: _player!.value.isPlaying,
        updatePosition: _player!.value.position,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (await _session?.setActive(true) ?? false) {
      return _player?.play() ?? Future.value();
    }
  }

  @override
  Future<void> pause() async {
    await _player?.pause();
    await _session?.setActive(false);
  }

  @override
  Future<void> seek(Duration position) async => _player?.seekTo(position);

  @override
  Future<void> stop() async {
    await _player?.pause();
    await _player?.seekTo(Duration.zero);
    await _session?.setActive(false);
  }

  @override
  Future<void> fastForward() async {
    if (_player == null) return;
    final newPosition = _player!.value.position + const Duration(seconds: 10);
    await _player!.seekTo(
      newPosition < _player!.value.duration
          ? newPosition
          : _player!.value.duration,
    );
  }

  @override
  Future<void> rewind() async {
    if (_player == null) return;
    final newPosition = _player!.value.position - const Duration(seconds: 10);
    await _player!.seekTo(
      newPosition > Duration.zero ? newPosition : Duration.zero,
    );
  }
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<StatefulWidget> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(widget.position)),
              Text(_formatDuration(widget.duration)),
            ],
          ),
        ),
        Slider(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: min(
            _dragValue ?? widget.position.inMilliseconds.toDouble(),
            widget.duration.inMilliseconds.toDouble(),
          ),
          onChanged: (value) {
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged!(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd!(Duration(milliseconds: value.round()));
            }
            _dragValue = null;
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return duration.inHours > 0
        ? '${twoDigits(duration.inHours)}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
