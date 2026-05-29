import 'dart:async';

import 'package:async/async.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;

/// An implementation of [AppMediaPlayer] that handles audio playback.
///
/// This service encapsulates a `just_audio` [AudioPlayer] instance. It listens
/// to the player's internal streams and broadcasts state changes via [stateStream],
/// allowing the rest of the application to react to audio events uniformly.
class AudioPlayerService implements AppMediaPlayer {
  final AudioSource _audioSource;

  final AudioPlayer _player = AudioPlayer(
    audioLoadConfiguration: AudioLoadConfiguration(
      darwinLoadControl: DarwinLoadControl(
        automaticallyWaitsToMinimizeStalling: false,
        canUseNetworkResourcesForLiveStreamingWhilePaused: true,
      ),
    ),
  );

  AudioPlayerService(this._audioSource);

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
      await _loadSound(autoPlay: autoPlay, loop: loop);
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

  Future<void> _loadSound({bool autoPlay = true, bool loop = false}) async {
    try {
      await _player.setAudioSource(_audioSource, preload: true);
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
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
  Stream<MediaPlayStreamData> get stateStream async* {
    final positionStream = _player.positionStream
        .asBroadcastStream()
        .handleError((e) => AppLogger.severe("$e", error: e));

    final eventStream = _player.playbackEventStream
        .asBroadcastStream()
        .handleError((e) => AppLogger.severe("$e", error: e));

    final durationStream = _player.durationStream
        .asBroadcastStream()
        .handleError((e) => AppLogger.severe("$e", error: e));

    final playerStream = _player.playerEventStream
        .asBroadcastStream()
        .handleError((e) => AppLogger.severe("$e", error: e));

    final stateStream = _player.playerStateStream
        .asBroadcastStream()
        .handleError((e) => AppLogger.severe("$e", error: e));

    final speedStream = _player.speedStream.asBroadcastStream().handleError(
      (e) => AppLogger.severe("$e", error: e),
    );

    final volumeStream = _player.volumeStream.asBroadcastStream().handleError(
      (e) => AppLogger.severe("$e", error: e),
    );

    final streams = StreamGroup.merge([
      positionStream,
      eventStream,
      durationStream,
      speedStream,
      stateStream,
      volumeStream,
      playerStream,
    ]);

    await for (final _ in streams) {
      final inDoneState = _player.processingState == ProcessingState.completed;
      yield (
        duration: _player.duration ?? 0.seconds,
        paused: !_player.playing || inDoneState,
        position: _player.position,
        playbackSpeed: _player.speed,
        state: MediaPlayerState.from(_player.processingState),
        volume: _player.volume,
      );
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
      await _player.dispose();
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
