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
