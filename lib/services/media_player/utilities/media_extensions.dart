import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
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

  YoutubePlayerController? get youtubeController {
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

  VideoPlayerController? get videoController {
    if (!isVideo) return null;
    return switch (mediaOrigin) {
      .asset => VideoPlayerController.asset(document as String),
      .file => VideoPlayerController.file(file!),
      .memory => VideoPlayerController.file(
        File.fromRawPath(document as Uint8List),
      ),
      .network => VideoPlayerController.networkUrl(
        Uri.parse(document as String),
      ),
      _ => null,
    };
  }

  AudioSource? get audioSource {
    if (!isAudio) return null;
    return switch (mediaOrigin) {
      .asset => AudioSource.asset(filePath!),
      .file => AudioSource.file(file!.path),
      .memory => AudioSource.file(File.fromRawPath(document as Uint8List).path),
      .network => AudioSource.uri(Uri.parse(fileUrl!)),
      _ => null,
    };
  }
}
