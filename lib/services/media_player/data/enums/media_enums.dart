import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum MediaPlayerState {
  ready(),
  buffering(),
  completed(),
  idle(),
  loading();

  const MediaPlayerState();

  bool get isBuffering => this == buffering;
  bool get isLoaded => this == ready || this == completed;

  factory MediaPlayerState.from(ProcessingState? state) {
    if (state == null) return MediaPlayerState.idle;
    return switch (state) {
      ProcessingState.ready => MediaPlayerState.ready,
      ProcessingState.buffering => MediaPlayerState.buffering,
      ProcessingState.completed => MediaPlayerState.completed,
      ProcessingState.loading => MediaPlayerState.loading,
      _ => MediaPlayerState.idle,
    };
  }

  factory MediaPlayerState.fromYoutubeValue(PlayerState? value) {
    if (value == null) return MediaPlayerState.idle;
    return switch (value) {
      PlayerState.buffering => MediaPlayerState.buffering,
      PlayerState.ended => MediaPlayerState.completed,
      _ => MediaPlayerState.ready,
    };
  }

  factory MediaPlayerState.fromVideoPlayerValue(VideoPlayerValue? value) {
    if (value == null) return MediaPlayerState.idle;
    if (value.isBuffering) return MediaPlayerState.buffering;
    if (value.isCompleted) return MediaPlayerState.completed;
    return MediaPlayerState.ready;
  }
}
