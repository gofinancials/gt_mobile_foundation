import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:gt_mobile_foundation/services/media_player/utilities/media_temp_files.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerPlatform originalPlatform;
  late _FakeVideoPlayerPlatform platform;
  late PathProviderPlatform originalPathProvider;
  late Directory tempDir;

  setUp(() {
    originalPlatform = VideoPlayerPlatform.instance;
    platform = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;

    originalPathProvider = PathProviderPlatform.instance;
    tempDir = Directory.systemTemp.createTempSync('gt_media_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    await platform.close();
    VideoPlayerPlatform.instance = originalPlatform;
    PathProviderPlatform.instance = originalPathProvider;
    tempDir.deleteSync(recursive: true);
  });

  group('MediaExtensions controller factories', () {
    test(
      'make controller allocation explicit and create fresh controllers',
      () {
        const data = AppAvData<String>(
          document: 'https://example.com/video.mp4',
          mediaType: AppMediaType.video,
        );

        final first = data.createVideoController();
        final second = data.createVideoController();

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(identical(first, second), isFalse);

        first!.dispose();
        second!.dispose();
      },
    );

    test('MediaSource creates exactly one controller for its media type', () {
      const data = AppAvData<String>(
        document: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        mediaType: AppMediaType.youtube,
      );

      final source = MediaSource(data);

      expect(source.youtube, isNotNull);
      expect(source.video, isNull);
      expect(source.audio, isNull);

      source.youtube!.dispose();
    });
  });

  group('platform controller lifecycle', () {
    test(
      'VideoPlayerService disposes its platform controller exactly once',
      () async {
        final source = MediaSource(
          const AppAvData<String>(
            document: 'https://example.com/video.mp4',
            mediaType: AppMediaType.video,
          ),
        );
        final service = VideoPlayerService(source.video!);

        final load = service.load(autoPlay: false);
        await _initializeNextPlayer(platform);
        await load;

        await service.dispose();
        await service.dispose();

        expect(platform.disposedPlayerIds, [0]);
      },
    );

    test('YoutubePlayerService disposes its controller exactly once', () async {
      final controller = _TrackingYoutubePlayerController();
      final service = YoutubePlayerService(controller);

      await service.dispose();
      await service.dispose();

      expect(controller.disposeCalls, 1);
    });
  });

  group('AppMediaPlayer ownership', () {
    test(
      'createSource does not complete until the new source is loaded',
      () async {
        final player = AppMediaPlayer();
        var completed = false;

        final creation = player
            .createSource(
              const AppAvData<String>(
                document: 'https://example.com/video.mp4',
                mediaType: AppMediaType.video,
              ),
              autoPlay: false,
            )
            .then((source) {
              completed = true;
              return source;
            });

        await _waitForPlayer(platform, 0);
        expect(completed, isFalse);

        platform.initializePlayer(0);
        final source = await creation;

        expect(source, isNotNull);
        expect(completed, isTrue);
        await player.dispose();
      },
    );

    test(
      'replacing a source disposes the old controller before returning',
      () async {
        final player = AppMediaPlayer();

        final firstCreation = player.createSource(
          const AppAvData<String>(
            id: 'first',
            document: 'https://example.com/first.mp4',
            mediaType: AppMediaType.video,
          ),
          autoPlay: false,
        );
        await _initializeNextPlayer(platform);
        final first = await firstCreation;

        final secondCreation = player.createSource(
          const AppAvData<String>(
            id: 'second',
            document: 'https://example.com/second.mp4',
            mediaType: AppMediaType.video,
          ),
          autoPlay: false,
        );
        await _initializeNextPlayer(platform);
        final second = await secondCreation;

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(identical(first!.video, second!.video), isFalse);
        expect(platform.disposedPlayerIds, [0]);

        await player.dispose();
        expect(platform.disposedPlayerIds, [0, 1]);
      },
    );

    test('unloadSource ignores a source that is not active', () async {
      final player = AppMediaPlayer();
      const data = AppAvData<String>(
        id: 'shared-id',
        document: 'https://example.com/video.mp4',
        mediaType: AppMediaType.video,
      );

      final creation = player.createSource(data, autoPlay: false);
      await _initializeNextPlayer(platform);
      final activeSource = (await creation)!;
      final equalButInactiveSource = MediaSource(data);

      expect(equalButInactiveSource, activeSource);
      await player.unloadSource(equalButInactiveSource);

      expect(platform.disposedPlayerIds, isEmpty);
      expect(player.duration, const Duration(seconds: 1));

      await equalButInactiveSource.video!.dispose();
      await player.unloadSource(activeSource);
      expect(platform.disposedPlayerIds, [0]);
    });
  });

  group('audio playback', () {
    const audio = AppAvData<String>(
      document: 'https://example.com/clip.mp3',
      mediaType: AppMediaType.audio,
    );

    test('MediaSource creates only an audio controller for audio media', () {
      final source = MediaSource(audio);

      expect(source.audio, isNotNull);
      expect(source.video, isNull);
      expect(source.youtube, isNull);
      expect(
        source
            .audio!
            .videoPlayerOptions
            ?.preventsDisplaySleepDuringVideoPlayback,
        isFalse,
      );

      source.audio!.dispose();
    });

    test('media matching audio and video gets only a video controller', () {
      final source = MediaSource(
        const AppAvData<String>(document: 'https://example.com/clip.mp4'),
      );

      expect(source.video, isNotNull);
      expect(source.audio, isNull);

      source.video!.dispose();
    });

    test('AppMediaPlayer disposes the audio controller exactly once', () async {
      final player = AppMediaPlayer();

      final creation = player.createSource(audio, autoPlay: false);
      await _initializeNextPlayer(platform);
      final source = await creation;

      expect(source?.isAudio, isTrue);
      await player.dispose();
      await player.dispose();
      expect(platform.disposedPlayerIds, [0]);
    });
  });

  group('in-memory media', () {
    final bytes = Uint8List.fromList(List.generate(64, (i) => i));

    test('plays bytes from a temp file that is deleted on dispose', () async {
      final player = AppMediaPlayer();

      final creation = player.createSource(
        AppAvData<Uint8List>(document: bytes, contentType: 'audio/mpeg'),
        autoPlay: false,
      );
      await _initializeNextPlayer(platform);
      final source = (await creation)!;
      final file = source.tempFile!;

      expect(source.isAudio, isTrue);
      expect(p.dirname(file.path), p.normalize(tempDir.absolute.path));
      expect(p.extension(file.path), '.mp3');
      expect(file.readAsBytesSync(), bytes);
      expect(source.audio!.dataSource, Uri.file(file.path).toString());

      await player.dispose();

      expect(file.existsSync(), isFalse);
      expect(platform.disposedPlayerIds, [0]);
    });

    test('plays video from the memory constructor', () async {
      final player = AppMediaPlayer();

      final creation = player.createSource(
        AppAvData<Uint8List>.memory(bytes, contentType: 'video/mp4'),
        autoPlay: false,
      );
      await _initializeNextPlayer(platform);
      final source = (await creation)!;
      final file = source.tempFile!;

      expect(source.isVideo, isTrue);
      expect(p.extension(file.path), '.mp4');
      expect(file.readAsBytesSync(), bytes);

      await player.dispose();
      expect(file.existsSync(), isFalse);
    });

    test('data URI strings get no controller instead of crashing', () async {
      const media = AppAvData<String>(
        document: 'data:video/mp4;base64,AAAA',
        mediaType: AppMediaType.video,
      );

      final source = await MediaSource.create(media);

      expect(source.video, isNull);
      expect(source.audio, isNull);
      expect(source.tempFile, isNull);
      expect(source.isValidSource, isFalse);
    });

    test('temp files keep an extension for common MIME aliases', () async {
      const expected = {
        'audio/mp3': '.mp3',
        'audio/x-m4a': '.m4a',
        'audio/wav': '.wav',
        'audio/mpeg': '.mp3',
      };

      for (final MapEntry(key: mimeType, value: extension)
          in expected.entries) {
        final source = await MediaSource.create(
          AppAvData<Uint8List>(document: bytes, contentType: mimeType),
        );

        expect(p.extension(source.tempFile!.path), extension, reason: mimeType);

        await source.audio!.dispose();
        await AppMediaTempFiles.delete(source.tempFile!);
      }
    });

    test('the synchronous constructor never treats bytes as a path', () {
      final source = MediaSource(
        AppAvData<Uint8List>(document: bytes, mediaType: AppMediaType.audio),
      );

      expect(source.audio, isNull);
      expect(source.video, isNull);
      expect(source.isValidSource, isFalse);
    });

    test('temp file extensions cannot add path segments', () async {
      final file = await AppMediaTempFiles.write(
        bytes,
        extension: '../../evil',
      );

      expect(p.dirname(file.path), p.normalize(tempDir.absolute.path));
      expect(p.extension(file.path), isEmpty);

      await AppMediaTempFiles.delete(file);
      expect(file.existsSync(), isFalse);
    });

    test('delete leaves files it did not create', () async {
      final other = File(p.join(tempDir.path, 'keep.mp3'))
        ..writeAsBytesSync(bytes);

      await AppMediaTempFiles.delete(other);

      expect(other.existsSync(), isTrue);
    });
  });
}

Future<void> _initializeNextPlayer(_FakeVideoPlayerPlatform platform) async {
  while (platform.streams.keys.every(platform.initializedPlayerIds.contains)) {
    await Future<void>.delayed(Duration.zero);
  }
  final playerId = platform.streams.keys.firstWhere(
    (id) => !platform.initializedPlayerIds.contains(id),
  );
  platform.initializePlayer(playerId);
}

Future<void> _waitForPlayer(
  _FakeVideoPlayerPlatform platform,
  int playerId,
) async {
  while (!platform.streams.containsKey(playerId)) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> streams = {};
  final List<int> disposedPlayerIds = [];
  final Set<int> initializedPlayerIds = {};
  int nextPlayerId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final playerId = nextPlayerId++;
    streams[playerId] = StreamController<VideoEvent>();
    return playerId;
  }

  void initializePlayer(int playerId) {
    initializedPlayerIds.add(playerId);
    streams[playerId]!.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 1),
        size: const Size(1920, 1080),
      ),
    );
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return streams[playerId]!.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    disposedPlayerIds.add(playerId);
  }

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  Future<void> close() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.temporaryPath);

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}

class _TrackingYoutubePlayerController extends YoutubePlayerController {
  _TrackingYoutubePlayerController() : super(initialVideoId: 'dQw4w9WgXcQ');

  int disposeCalls = 0;

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}
