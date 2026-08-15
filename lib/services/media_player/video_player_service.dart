import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';
import 'package:video_player/video_player.dart';

/// An implementation of [AppMediaPlayer] and [CaptionablePlayer] that handles video playback.
///
/// This service encapsulates a [VideoPlayerController]. It internally converts
/// the controller's [ValueNotifier] updates into a reactive [stateStream] so that
/// the UI can bind to video playback state seamlessly using the unified pattern.
class VideoPlayerService implements AppMediaPlayerService, CaptionablePlayer {
  final VideoPlayerController _controller;
  @override
  final OnChanged<MediaPlayStreamData>? onUpdate;
  late final StreamController<MediaPlayStreamData> _stateStreamController;
  bool _isUnloaded = false;
  bool _isDisposed = false;

  VideoPlayerService(this._controller, {this.onUpdate}) {
    _stateStreamController = StreamController<MediaPlayStreamData>.broadcast();
    _controller.addListener(_ctrlListener);
  }

  void _ctrlListener() {
    onUpdate?.call(playData);
    if (_stateStreamController.isClosed) return;
    _stateStreamController.add(playData);
  }

  @override
  MediaPlayStreamData get playData {
    return (
      duration: _controller.value.duration,
      paused: !(_controller.value.isPlaying),
      position: _controller.value.position,
      playbackSpeed: _controller.value.playbackSpeed,
      state: MediaPlayerState.fromVideoPlayerValue(_controller.value),
      volume: _controller.value.volume,
    );
  }

  @override
  Stream<MediaPlayStreamData> get stateStream => _stateStreamController.stream;

  @override
  Future<void> load({bool autoPlay = true}) async {
    try {
      pause();
      final isInitialised = _controller.value.isInitialized;
      if (!isInitialised) await _controller.initialize();
      if (autoPlay) await play();
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  @override
  bool get isPlaying {
    try {
      return _controller.value.isPlaying;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return false;
    }
  }

  @override
  bool get isCompleted {
    try {
      return _controller.value.isCompleted;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return false;
    }
  }

  @override
  Future<void> play() async {
    try {
      if (_controller.value.isPlaying) return;
      await _controller.play();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (!_controller.value.isPlaying) return;
      await _controller.pause();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> togglePlay() async {
    try {
      final playing = _controller.value.isPlaying;
      if (playing) {
        await pause();
        return;
      }
      await play();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> toggleMute() async {
    try {
      final volume = _controller.value.volume;
      await _controller.setVolume(volume > 0 ? 0 : 1);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> seekTo(Duration duration) async {
    try {
      await _controller.seekTo(duration);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Duration? get duration {
    try {
      return _controller.value.duration;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return null;
    }
  }

  @override
  Duration? get position {
    try {
      return _controller.value.position;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return null;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _controller.setPlaybackSpeed(speed);
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
    if (_isUnloaded) return;
    _isUnloaded = true;
    await reset();
    _controller.removeListener(_ctrlListener);
    await _stateStreamController.close();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      await unloadSource();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
    try {
      await _controller.dispose();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> setCaption(SubRipCaptionFile caption) async {
    try {
      await _controller.setClosedCaptionFile(Future.value(caption));
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }
}
