import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';
import 'package:video_player/video_player.dart';

/// Defines the unified strategy interface for all media players.
///
/// This interface abstracts the underlying player implementations (like video,
/// audio, and youtube) so that the [MediaPlayerService] can interact with them
/// polymorphically without needing to know the specific controller types.
abstract class AppMediaPlayerService {
  /// Loads the given [MediaSource] into the player.
  Future<void> load({required bool autoPlay});

  /// Toggles the playback state between playing and paused.
  Future<void> togglePlay();

  /// Toggles the player's mute state.
  Future<void> toggleMute();

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses the current playback.
  Future<void> pause();

  /// Returns `true` if the media is currently playing.
  bool get isPlaying;

  /// Returns `true` if the media playback has reached the end.
  bool get isCompleted;

  /// Seeks to a specific [duration] in the media timeline.
  Future<void> seekTo(Duration duration);

  /// Returns the total duration of the currently loaded media, if available.
  Duration? get duration;

  /// Returns the current playback position, if available.
  Duration? get position;

  /// Sets the playback speed (e.g., 1.0 for normal speed, 2.0 for double speed).
  Future<void> setSpeed(double speed);

  /// Retrieves a snapshot of the current playback state and data.
  MediaPlayStreamData get playData;

  /// A reactive stream broadcasting changes to the playback state.
  Stream<MediaPlayStreamData> get stateStream;

  /// Pauses and resets the playback position to the beginning.
  Future<void> reset();

  /// Stops playback and releases the currently loaded source.
  Future<void> unloadSource();

  /// Disposes of the player and cleans up any allocated resources.
  Future<void> dispose();

  /// A callback that is invoked when the playback state changes.
  OnChanged<MediaPlayStreamData>? get onUpdate;
}

/// An interface for media players that support closed captions.
abstract class CaptionablePlayer {
  /// Sets the active [SubRipCaptionFile] for the player to display.
  Future<void> setCaption(SubRipCaptionFile caption);
}
