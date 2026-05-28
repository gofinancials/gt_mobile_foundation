import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';
import 'package:video_player/video_player.dart';

/// A facade service that orchestrates various media players using the Strategy Pattern.
///
/// This service acts as the central point for loading and controlling media.
/// It dynamically assigns the appropriate [AppMediaPlayer] implementation
/// based on the [MediaSource] type (audio, video, or youtube) and delegates
/// playback commands to it.
class MediaPlayerService {
  final Map<String, MediaSource> _sourceCache = {};
  MediaSource? _currentSource;
  AppMediaPlayer? _activePlayer;

  /// Retrieves and loads a media source for the provided [AppAvData].
  /// Returns the initialized [MediaSource] if successful, or `null` otherwise.
  Future<MediaSource?> getSource(AppAvData data) async {
    _currentSource = null;
    final source = _retrieveSource(data);
    if (source == null || !source.isValidSource) return null;
    _currentSource = source;
    await _loadSource(_currentSource);
    return _currentSource;
  }

  /// Retrieves a source from the internal cache, or creates and caches it if it does not exist.
  MediaSource? _retrieveSource(AppAvData data) {
    final source = MediaSource(data);
    final id = source.id;

    if (!id.hasValue || !source.isValidSource) return null;
    if (!_sourceCache.containsKey(id)) _sourceCache[id!] = source;

    return _sourceCache[id];
  }

  /// Instantiates the appropriate [AppMediaPlayer] for the given [source] and loads it.
  Future<void> _loadSource(MediaSource? source) async {
    if (_activePlayer != null) {
      await _activePlayer!.dispose();
    }

    if (source == null || !source.isValidSource) {
      _activePlayer = null;
      return;
    }

    if (source.isYoutube) {
      _activePlayer = YoutubePlayerService();
    } else if (source.isVideo) {
      _activePlayer = VideoPlayerService();
    } else if (source.isAudio) {
      _activePlayer = AudioPlayerService();
    } else {
      _activePlayer = null;
      return;
    }

    await _activePlayer!.load(source);
  }

  /// Returns `true` if the active player is currently playing.
  bool get isPlaying => _activePlayer?.isPlaying ?? false;

  /// Returns `true` if the active player has completed playback.
  bool get isCompleted => _activePlayer?.isCompleted ?? false;

  /// Returns the currently active [MediaSource].
  MediaSource? get currentSource => _currentSource;

  /// Retrieves a snapshot of the current playback data from the active player.
  MediaPlayStreamData get playData {
    return _activePlayer?.playData ??
        (
          duration: 1.seconds,
          paused: true,
          position: 0.seconds,
          playbackSpeed: 1,
          state: MediaPlayerState.idle,
          volume: 1,
        );
  }

  /// Starts or resumes playback on the active player.
  Future<void> play() async {
    try {
      await _activePlayer?.play();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  /// Pauses playback on the active player.
  Future<void> pause() async {
    try {
      await _activePlayer?.pause();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  /// Toggles playback between playing and paused.
  Future<void> togglePlay() async {
    try {
      await _activePlayer?.togglePlay();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  /// Toggles the mute state of the active player.
  Future<void> toggleMute() async {
    try {
      await _activePlayer?.toggleMute();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  /// Seeks to the specified [duration] in the active player.
  Future<void> seekTo(Duration duration) async {
    try {
      await _activePlayer?.seekTo(duration);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  /// Returns the duration of the current media.
  Duration? get duration => _activePlayer?.duration;

  /// Returns the current playback position.
  Duration? get position => _activePlayer?.position;

  /// Sets the playback speed on the active player.
  Future<void> setSpeed(double speed) async {
    try {
      await _activePlayer?.setSpeed(speed);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  /// Returns a stream of playback state changes from the active player.
  Stream<MediaPlayStreamData> getSourceEvents() {
    return _activePlayer?.stateStream ?? const Stream.empty();
  }

  /// Sets the closed caption file for players that support it (e.g., VideoPlayer).
  Future<void> setCaption(SubRipCaptionFile caption) async {
    if (_activePlayer is CaptionablePlayer) {
      await (_activePlayer as CaptionablePlayer).setCaption(caption);
    }
  }

  /// Unloads the specified [source], disposing of its player and removing it from the cache.
  Future<void> unloadSource(MediaSource source) async {
    final id = source.id;
    if (id != null && _sourceCache.containsKey(id)) {
      _sourceCache.remove(id);
    }
    if (_currentSource?.id == id) {
      await _activePlayer?.unloadSource();
      _activePlayer = null;
      _currentSource = null;
    }
  }

  /// Resets the active player to the beginning and pauses playback.
  Future<void> reset() async {
    await _activePlayer?.reset();
  }

  /// Disposes of the active player and clears the source cache.
  Future<void> dispose() async {
    await _activePlayer?.dispose();
    _activePlayer = null;
    _currentSource = null;
    _sourceCache.clear();
  }

  /// Returns a list of all currently cached [MediaSource] objects.
  List<MediaSource> get sources {
    return _sourceCache.values.toList();
  }
}
