import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

void main() {
  late _FakeSharePlatform platform;

  // SharePlus.instance captures SharePlatform.instance on first access, so the
  // fake must be installed before anything touches SharePlus.instance.
  setUpAll(() {
    platform = _FakeSharePlatform();
    SharePlatform.instance = platform;
  });

  setUp(() => platform.lastParams = null);

  final pngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    ...List.filled(24, 0),
  ]);
  final unknownBytes = Uint8List.fromList(List.filled(32, 0x01));

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(key: Key('host'), width: 100, height: 100),
      ),
    );
    return tester.element(find.byKey(const Key('host')));
  }

  group('AppSharePlugin.shareFile', () {
    testWidgets('sends text with the file and keeps title as sheet title', (
      tester,
    ) async {
      final context = await pumpContext(tester);

      AppSharePlugin.shareFile(
        context,
        data: pngBytes,
        title: 'Kids login',
        text: "Scan this QR code to log in to Ada's Kids account.",
      );

      final params = platform.lastParams!;
      expect(params.text, "Scan this QR code to log in to Ada's Kids account.");
      expect(params.title, 'Kids login');
      expect(params.files, hasLength(1));
    });

    testWidgets('treats empty text as absent', (tester) async {
      final context = await pumpContext(tester);

      AppSharePlugin.shareFile(context, data: pngBytes, text: '');

      expect(platform.lastParams!.text, isNull);
    });

    testWidgets('infers mime type and default file name from data', (
      tester,
    ) async {
      final context = await pumpContext(tester);

      AppSharePlugin.shareFile(context, data: pngBytes);

      final params = platform.lastParams!;
      expect(params.files!.single.mimeType, 'image/png');
      expect(params.fileNameOverrides, ['file.png']);
    });

    testWidgets('still infers pdf for pdf data shared without a type', (
      tester,
    ) async {
      final context = await pumpContext(tester);
      final pdfBytes = Uint8List.fromList([
        ...'%PDF-1.4\n'.codeUnits,
        ...List.filled(24, 0),
      ]);

      AppSharePlugin.shareFile(context, data: pdfBytes);

      final params = platform.lastParams!;
      expect(params.files!.single.mimeType, 'application/pdf');
      expect(params.fileNameOverrides, ['file.pdf']);
    });

    testWidgets('infers mime type from file name when data is unrecognised', (
      tester,
    ) async {
      final context = await pumpContext(tester);

      AppSharePlugin.shareFile(
        context,
        data: unknownBytes,
        fileName: 'statement.pdf',
      );

      final params = platform.lastParams!;
      expect(params.files!.single.mimeType, 'application/pdf');
      expect(params.fileNameOverrides, ['statement.pdf']);
    });

    testWidgets('falls back to octet-stream with a neutral file name', (
      tester,
    ) async {
      final context = await pumpContext(tester);

      AppSharePlugin.shareFile(context, data: unknownBytes);

      final params = platform.lastParams!;
      expect(params.files!.single.mimeType, 'application/octet-stream');
      expect(params.fileNameOverrides, ['file.bin']);
    });

    testWidgets('explicit mime type wins over inference', (tester) async {
      final context = await pumpContext(tester);

      AppSharePlugin.shareFile(
        context,
        data: pngBytes,
        mimeType: 'image/jpeg',
        fileName: 'qr',
      );

      final params = platform.lastParams!;
      expect(params.files!.single.mimeType, 'image/jpeg');
      expect(params.fileNameOverrides, ['qr']);
    });
  });

  group('BuildContext.shareFile', () {
    testWidgets('forwards text to the plugin', (tester) async {
      final context = await pumpContext(tester);

      context.shareFile(pngBytes, text: 'Here is your QR code');

      final params = platform.lastParams!;
      expect(params.text, 'Here is your QR code');
      expect(params.files!.single.mimeType, 'image/png');
    });
  });
}

class _FakeSharePlatform extends SharePlatform {
  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    lastParams = params;
    return const ShareResult('', ShareResultStatus.success);
  }
}
