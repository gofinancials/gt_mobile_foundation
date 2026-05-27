import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';
import 'package:video_player/video_player.dart';

/// An implementation of [AppMediaPlayer] and [CaptionablePlayer] that handles video playback.
///
/// This service encapsulates a [VideoPlayerController]. It internally converts
/// the controller's [ValueNotifier] updates into a reactive [stateStream] so that
/// the UI can bind to video playback state seamlessly using the unified pattern.
class VideoPlayerService implements AppMediaPlayer, CaptionablePlayer {
  VideoPlayerController? _controller;
  final StreamController<MediaPlayStreamData> _stateStreamController =
      StreamController<MediaPlayStreamData>.broadcast();

  VideoPlayerService();

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
      duration: _controller!.value.duration,
      paused: !(_controller!.value.isPlaying),
      position: _controller!.value.position,
      playbackSpeed: _controller!.value.playbackSpeed,
      state: MediaPlayerState.fromVideoPlayerValue(_controller!.value),
      volume: _controller!.value.volume,
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
      if (source.video == null) return;
      
      await unloadSource();

      _controller = source.video;
      _controller!.addListener(_onControllerUpdate);

      final isInitialised = _controller!.value.isInitialized;
      if (!isInitialised) {
        await _controller!.initialize();
      }
      await _controller!.setLooping(true);
      _onControllerUpdate();
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  @override
  bool get isPlaying {
    try {
      return _controller?.value.isPlaying ?? false;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return false;
    }
  }

  @override
  bool get isCompleted {
    try {
      return _controller?.value.isCompleted ?? false;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return false;
    }
  }

  @override
  Future<void> play() async {
    try {
      if (_controller == null || _controller!.value.isPlaying) return;
      await _controller!.play();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_controller == null || !_controller!.value.isPlaying) return;
      await _controller!.pause();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> togglePlay() async {
    try {
      final playing = _controller?.value.isPlaying ?? false;
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
      await _controller!.setVolume(volume > 0 ? 0 : 1);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> seekTo(Duration duration) async {
    try {
      await _controller?.seekTo(duration);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Duration? get duration {
    try {
      return _controller?.value.duration;
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
      await _controller?.setPlaybackSpeed(speed);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> reset() async {
    try {
      await pause();
      await seekTo(0.milliseconds);
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

  @override
  Future<void> setCaption(SubRipCaptionFile caption) async {
    try {
      await _controller?.setClosedCaptionFile(Future.value(caption));
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }
}
