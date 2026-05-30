import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;

/// An implementation of [AppMediaPlayer] that handles audio playback.
///
/// This service encapsulates a `just_audio` [AudioPlayer] instance. It listens
/// to the player's internal streams and broadcasts state changes via [stateStream],
/// allowing the rest of the application to react to audio events uniformly.
class AudioPlayerService implements AppMediaPlayerService {
  final AudioSource _audioSource;
  @override
  final OnChanged<MediaPlayStreamData>? onUpdate;
  late final StreamController<MediaPlayStreamData> _stateStreamController;

  final AudioPlayer _player = AudioPlayer(
    audioLoadConfiguration: AudioLoadConfiguration(
      darwinLoadControl: DarwinLoadControl(
        automaticallyWaitsToMinimizeStalling: false,
        canUseNetworkResourcesForLiveStreamingWhilePaused: true,
      ),
    ),
  );

  AudioPlayerService(this._audioSource, {this.onUpdate}) {
    _stateStreamController = StreamController<MediaPlayStreamData>();
    _observePlayback();
  }

  @override
  MediaPlayStreamData get playData {
    return (
      duration: _player.duration ?? 0.seconds,
      paused: !_player.playing || isCompleted,
      position: _player.position,
      playbackSpeed: _player.speed,
      state: MediaPlayerState.from(_player.processingState),
      volume: _player.volume,
    );
  }

  @override
  Future<void> load({bool autoPlay = true, bool loop = false}) async {
    try {
      await pause();
      await _loadSound(autoPlay: autoPlay);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  bool get isPlaying {
    return _player.playing;
  }

  @override
  bool get isCompleted {
    return _player.processingState == ProcessingState.completed;
  }

  Future<void> _loadSound({bool autoPlay = true}) async {
    try {
      await _player.setAudioSource(_audioSource, preload: true);
      if (autoPlay) await play();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> togglePlay() async {
    try {
      if (!isPlaying) {
        await _player.play();
        return;
      }
      if (isCompleted) {
        await seekTo(0.seconds);
        await _player.play();
        return;
      }
      await _player.pause();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> toggleMute() async {
    try {
      await _player.setVolume(_player.volume > 0 ? 0 : 1);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> seekTo(Duration duration) async {
    try {
      await _player.seek(duration);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Duration? get duration {
    try {
      return _player.duration;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return null;
    }
  }

  @override
  Duration? get position {
    try {
      return _player.position;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return null;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Stream<MediaPlayStreamData> get stateStream => _stateStreamController.stream;

  Stream<MediaPlayStreamData> _observePlayback() async* {
    final eventStream = _player.playbackEventStream
        .asBroadcastStream()
        .handleError((e) => AppLogger.severe("$e", error: e));

    await for (final event in eventStream) {
      if (_stateStreamController.isClosed) break;

      final inDoneState = _player.processingState == ProcessingState.completed;
      final data = (
        duration: event.duration ?? playData.duration,
        paused: !_player.playing || inDoneState,
        position: event.updatePosition,
        playbackSpeed: _player.speed,
        state: MediaPlayerState.from(event.processingState),
        volume: _player.volume,
      );
      _stateStreamController.add(data);
      onUpdate?.call(data);
      yield data;
    }
  }

  @override
  Future<void> unloadSource() async {
    try {
      await stop();
      _player.removeAudioSourceAt(0);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await unloadSource();
      _stateStreamController.close();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  @override
  Future<void> reset() async {
    await seekTo(0.milliseconds);
    await pause();
  }
}
