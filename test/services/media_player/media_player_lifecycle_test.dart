import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerPlatform originalPlatform;
  late _FakeVideoPlayerPlatform platform;

  setUp(() {
    originalPlatform = VideoPlayerPlatform.instance;
    platform = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  tearDown(() async {
    await platform.close();
    VideoPlayerPlatform.instance = originalPlatform;
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

class _TrackingYoutubePlayerController extends YoutubePlayerController {
  _TrackingYoutubePlayerController() : super(initialVideoId: 'dQw4w9WgXcQ');

  int disposeCalls = 0;

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}
