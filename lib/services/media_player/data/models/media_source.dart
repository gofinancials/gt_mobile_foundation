import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MediaSource extends Equatable {
  final AppAvData media;
  final VideoPlayerController? video;
  final YoutubePlayerController? youtube;
  final VideoPlayerController? audio;

  const MediaSource._(this.media, {this.video, this.youtube, this.audio});

  /// Creates a source for [media] with controllers owned by the caller.
  ///
  /// An audio controller is only created for media that is not also video.
  /// In-memory media gets no controller, because the platform players only
  /// read assets, files and URLs.
  MediaSource(this.media)
    : video = media.createVideoController(),
      youtube = media.createYoutubeController(),
      audio = media.isVideo ? null : media.createAudioController();

  MediaSource copyWith({
    AppAvData? media,
    VideoPlayerController? video,
    YoutubePlayerController? youtube,
    VideoPlayerController? audio,
  }) {
    return MediaSource._(
      media ?? this.media,
      video: video ?? this.video,
      youtube: youtube ?? this.youtube,
      audio: audio ?? this.audio,
    );
  }

  bool get isValidSource {
    if (!media.isValid || mediaType == null) return false;
    return isAudio || isVideo || isYoutube;
  }

  String get id => "${media.id ?? media.hashCode}";

  bool get isAudio => media.isAudio && audio != null;
  bool get isVideo => media.isVideo && video != null;
  bool get isYoutube => media.isYoutube && youtube != null;

  AppMediaType? get mediaType {
    if (media.mediaType != null) return media.mediaType!;
    if (isAudio) return AppMediaType.audio;
    if (isVideo) return AppMediaType.video;
    if (isYoutube) return AppMediaType.youtube;
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    video?.dataSource,
    youtube?.initialVideoId,
    audio?.dataSource,
  ];
}
