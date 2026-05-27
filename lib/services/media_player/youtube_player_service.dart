import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// An implementation of [AppMediaPlayer] that handles YouTube video playback.
///
/// This service encapsulates a [YoutubePlayerController] from `youtube_player_flutter`.
/// It converts the controller's state changes into the unified [MediaPlayStreamData]
/// format and broadcasts them via [stateStream].
class YoutubePlayerService implements AppMediaPlayer {
  YoutubePlayerController? _controller;
  final StreamController<MediaPlayStreamData> _stateStreamController =
      StreamController<MediaPlayStreamData>.broadcast();

  YoutubePlayerService();

  @override
  MediaPlayStreamData get playData {
    if (_controller == null) {
      return (
        duration: 1.seconds,
        paused: true,
        position: 0.seconds,
        playbackSpeed: 1,
        state: MediaPlayerState.idle,
        volume: 1,
      );
    }
    return (
      duration: duration ?? 1.seconds,
      paused: !isPlaying,
      position: position ?? 0.seconds,
      playbackSpeed: _controller!.value.playbackRate,
      state: MediaPlayerState.fromYoutubeValue(_controller!.value.playerState),
      volume: (_controller!.value.volume).toDouble(),
    );
  }

  @override
  Stream<MediaPlayStreamData> get stateStream => _stateStreamController.stream;

  void _onControllerUpdate() {
    if (!_stateStreamController.isClosed) {
      _stateStreamController.add(playData);
    }
  }

  @override
  Future<void> load(MediaSource source) async {
    try {
      if (source.youtube == null) return;

      await unloadSource();

      _controller = source.youtube;
      _controller!.addListener(_onControllerUpdate);

      _controller!.load(_controller!.initialVideoId);
      _onControllerUpdate();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  bool get isPlaying {
    try {
      return _controller?.value.isPlaying ?? false;
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return false;
    }
  }

  @override
  bool get isCompleted {
    try {
      return _controller?.value.playerState == PlayerState.ended;
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return false;
    }
  }

  @override
  Future<void> play() async {
    try {
      if (_controller == null || _controller!.value.isPlaying) return;
      _controller!.play();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_controller == null || !_controller!.value.isPlaying) return;
      _controller!.pause();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> togglePlay() async {
    try {
      if (_controller == null) return;
      final playing = _controller!.value.isPlaying;
      if (playing) {
        await pause();
      } else {
        await play();
      }
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> toggleMute() async {
    try {
      if (_controller == null) return;
      final volume = _controller!.value.volume;
      _controller!.setVolume(volume > 0 ? 0 : 1);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> seekTo(Duration duration) async {
    try {
      _controller?.seekTo(duration);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Duration? get duration {
    try {
      return _controller?.value.metaData.duration;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return null;
    }
  }

  @override
  Duration? get position {
    try {
      return _controller?.value.position;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return null;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      _controller?.setPlaybackRate(speed);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> reset() async {
    try {
      await pause();
      _controller?.reset();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> unloadSource() async {
    if (_controller != null) {
      await reset();
      _controller!.removeListener(_onControllerUpdate);
      _controller = null;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await unloadSource();
      await _stateStreamController.close();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }
}
