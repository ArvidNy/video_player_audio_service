import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_audio_service/video_player.dart';

late AudioHandler _audioHandler;

Future<void> main() async {
  _audioHandler = await AudioService.init(
    builder: () => VideoPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.videoPlayerAudioService.audio',
      androidNotificationChannelName: 'Video playback',
      androidNotificationOngoing: true,
    ),
  );
  runApp(const MainScreen());
}


class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Video Service Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: 240,
                child: _buildVideoPlayer(),
              ),
              const SizedBox(height: 20),
              StreamBuilder<MediaItem?>(
                stream: _audioHandler.mediaItem,
                builder: (context, snapshot) {
                  final mediaItem = snapshot.data;
                  return Text(mediaItem?.title ?? '');
                },
              ),
              StreamBuilder<bool>(
                stream:
                    _audioHandler.playbackState
                        .map((state) => state.playing)
                        .distinct(),
                builder: (context, snapshot) {
                  final playing = snapshot.data ?? false;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _button(Icons.fast_rewind, _audioHandler.rewind),
                      if (playing)
                        _button(Icons.pause, _audioHandler.pause)
                      else
                        _button(Icons.play_arrow, _audioHandler.play),
                      _button(Icons.stop, _audioHandler.stop),
                      _button(Icons.fast_forward, _audioHandler.fastForward),
                    ],
                  );
                },
              ),
              StreamBuilder<MediaState>(
                stream: _mediaStateStream,
                builder: (context, snapshot) {
                  final mediaState = snapshot.data;
                  return SeekBar(
                    duration: mediaState?.mediaItem?.duration ?? Duration.zero,
                    position: mediaState?.position ?? Duration.zero,
                    onChangeEnd: (newPosition) {
                      _audioHandler.seek(newPosition);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return StreamBuilder<VideoPlayerController?>(
      stream: (_audioHandler as VideoPlayerHandler).playerController,
      builder: (context, snapshot) {
        final controller = snapshot.data;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );
      },
    );
  }

  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
        _audioHandler.mediaItem,
        AudioService.position,
        (mediaItem, position) => MediaState(mediaItem, position),
      );

  IconButton _button(IconData iconData, VoidCallback onPressed) =>
      IconButton(icon: Icon(iconData), iconSize: 64.0, onPressed: onPressed);
}