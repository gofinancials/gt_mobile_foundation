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
  StreamSubscription? _stateSubscription;
  StreamSubscription? _positionSubscription;
  late final StreamController<MediaPlayStreamData> _stateStreamController;
  bool _isUnloaded = false;
  bool _isDisposed = false;

  final AudioPlayer _player = AudioPlayer(
    audioLoadConfiguration: AudioLoadConfiguration(
      darwinLoadControl: DarwinLoadControl(
        automaticallyWaitsToMinimizeStalling: false,
        canUseNetworkResourcesForLiveStreamingWhilePaused: true,
      ),
    ),
  );

  AudioPlayerService(this._audioSource, {this.onUpdate}) {
    _stateStreamController = StreamController<MediaPlayStreamData>.broadcast();
    _observeState();
    _observePosition();
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
      await _player.setAudioSource(_audioSource);
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

  void _observePosition() {
    _positionSubscription?.cancel();
    _positionSubscription = _player.positionStream.listen(
      (event) {
        if (_stateStreamController.isClosed) return;
        _stateStreamController.add(playData);
        onUpdate?.call(playData);
      },
      onError: (e) {
        AppLogger.severe("$e", error: e);
      },
    );
  }

  void _observeState() {
    _stateSubscription?.cancel();
    _stateSubscription = _player.playerStateStream.listen(
      (event) {
        if (_stateStreamController.isClosed) return;
        _stateStreamController.add(playData);
        onUpdate?.call(playData);
      },
      onError: (e) {
        AppLogger.severe("$e", error: e);
      },
    );
  }

  @override
  Future<void> unloadSource() async {
    if (_isUnloaded) return;
    _isUnloaded = true;
    try {
      await stop();
      _stateSubscription?.cancel();
      _positionSubscription?.cancel();
      _player.removeAudioSourceAt(0);
      _stateStreamController.close();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
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
