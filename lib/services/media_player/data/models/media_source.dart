import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:gt_mobile_foundation/services/media_player/utilities/media_temp_files.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MediaSource extends Equatable {
  final AppAvData media;
  final VideoPlayerController? video;
  final YoutubePlayerController? youtube;
  final VideoPlayerController? audio;

  /// Temporary copy of in-memory [media], deleted by the player that loads
  /// this source.
  final File? tempFile;

  const MediaSource._(
    this.media, {
    this.video,
    this.youtube,
    this.audio,
    this.tempFile,
  });

  /// Creates a source for [media] with controllers owned by the caller.
  ///
  /// An audio controller is only created when there is no video controller.
  /// In-memory media gets no controller here; use [create] instead.
  factory MediaSource(AppAvData media) {
    final video = media.createVideoController();
    return MediaSource._(
      media,
      video: video,
      youtube: media.createYoutubeController(),
      audio: video == null ? media.createAudioController() : null,
    );
  }

  /// Creates a source for [media], copying in-memory media to a temporary file.
  ///
  /// Platform players cannot read raw bytes, so in-memory audio and video are
  /// written to the app's temporary directory first. The player that loads the
  /// source deletes [tempFile] when it is disposed.
  static Future<MediaSource> create(AppAvData media) async {
    if (media.mediaOrigin != AppMediaOrigin.memory) return MediaSource(media);

    final bytes = media.bytesData;
    if (bytes == null || !(media.isVideo || media.isAudio)) {
      return MediaSource._(media);
    }

    try {
      final file = await AppMediaTempFiles.write(
        bytes,
        extension: _extensionFor(media),
      );
      final fileMedia = AppAvData<File>(
        document: file,
        id: media.id,
        mediaType: media.isVideo ? AppMediaType.video : AppMediaType.audio,
      );
      return MediaSource._(
        media,
        video: fileMedia.createVideoController(),
        audio: fileMedia.createAudioController(),
        tempFile: file,
      );
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return MediaSource._(media);
    }
  }

  /// Common MIME aliases that `package:mime` does not map to an extension.
  static const _mimeExtensionAliases = {
    "audio/mp3": "mp3",
    "audio/x-m4a": "m4a",
    "audio/wav": "wav",
  };

  /// Picks a file extension for in-memory [media] from its name or MIME type.
  static String? _extensionFor(AppAvData media) {
    final fromName = p.extension(media.name ?? "");
    if (fromName.length > 1) return fromName.substring(1);
    final mimeType = media.mimeType.toLowerCase();
    return extensionFromMime(mimeType) ?? _mimeExtensionAliases[mimeType];
  }

  MediaSource copyWith({
    AppAvData? media,
    VideoPlayerController? video,
    YoutubePlayerController? youtube,
    VideoPlayerController? audio,
    File? tempFile,
  }) {
    return MediaSource._(
      media ?? this.media,
      video: video ?? this.video,
      youtube: youtube ?? this.youtube,
      audio: audio ?? this.audio,
      tempFile: tempFile ?? this.tempFile,
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
