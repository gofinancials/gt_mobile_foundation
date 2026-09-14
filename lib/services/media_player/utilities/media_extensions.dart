import 'package:gt_mobile_foundation/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

extension MediaExtensions on AppAvData {
  String? _getVideoId(String url) {
    try {
      if (url.startsWith("http:")) url = url.replaceFirst("http:", "https:");

      return YoutubePlayer.convertUrlToId(url);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return null;
    }
  }

  /// Creates a YouTube controller owned by the caller.
  YoutubePlayerController? createYoutubeController() {
    if (!isYoutube) return null;
    final videoId = _getVideoId(fileUrl!);
    if (videoId == null) return null;
    return YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        hideControls: true,
        autoPlay: true,
        enableCaption: false,
        loop: false,
        showLiveFullscreenButton: false,
      ),
    );
  }

  /// Creates a video controller owned by the caller.
  ///
  /// Returns `null` for in-memory media; the platform player only reads
  /// assets, files and URLs.
  VideoPlayerController? createVideoController() {
    if (!isVideo) return null;
    return _createPlayerController();
  }

  /// Creates an audio controller owned by the caller.
  ///
  /// Audio plays through `video_player` and lets the display sleep during
  /// playback. Returns `null` for in-memory media.
  VideoPlayerController? createAudioController() {
    if (!isAudio) return null;
    return _createPlayerController(
      options: VideoPlayerOptions(
        preventsDisplaySleepDuringVideoPlayback: false,
      ),
    );
  }

  @Deprecated(
    'This getter allocates a controller. Use createYoutubeController() and '
    'dispose the returned controller.',
  )
  YoutubePlayerController? get youtubeController => createYoutubeController();

  @Deprecated(
    'This getter allocates a controller. Use createVideoController() and '
    'dispose the returned controller.',
  )
  VideoPlayerController? get videoController => createVideoController();

  VideoPlayerController? _createPlayerController({
    VideoPlayerOptions? options,
  }) {
    if (!isValid) return null;
    return switch (mediaOrigin) {
      .asset => VideoPlayerController.asset(
        filePath!,
        videoPlayerOptions: options,
      ),
      .file => VideoPlayerController.file(file!, videoPlayerOptions: options),
      .network => VideoPlayerController.networkUrl(
        Uri.parse(fileUrl!),
        videoPlayerOptions: options,
      ),
      _ => null,
    };
  }
}
