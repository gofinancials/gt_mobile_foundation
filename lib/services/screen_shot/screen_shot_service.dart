// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:flutter/rendering.dart';

class ScreenShotService {
  final GlobalKey screenShotKey = GlobalKey();

  Future<List<Uint8List?>> captureLongScreen(
    BuildContext context, {
    required ScrollController scrollController,
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 20),
  }) async {
    try {
      final scrollHeight = scrollController.position.maxScrollExtent;

      final screenSize = MediaQuery.sizeOf(context);
      final screenOrientation = MediaQuery.orientationOf(context);

      final screenHeight = screenOrientation == Orientation.portrait
          ? screenSize.height
          : screenSize.width;
      final computedHeight =
          screenHeight - (kToolbarHeight + kBottomNavigationBarHeight);

      final pageCount = (scrollHeight / computedHeight).ceil() + 1;

      List<Uint8List?> imageFutures = [];

      final pages = List.generate(pageCount, (index) => index);

      await Future.forEach(pages, (i) async {
        scrollController.jumpTo(screenHeight * i);
        final image = await captureScreen(
          context,
          pixelRatio: pixelRatio,
          delay: delay,
        );
        if (image == null) return;
        imageFutures.tryAdd(image);
      });

      return imageFutures;
    } catch (_) {
      return [];
    }
  }

  Future<Uint8List?> captureScreen(
    BuildContext context, {
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 20),
  }) async {
    try {
      return await Future.delayed(delay, () async {
        final RenderRepaintBoundary? boundary =
            screenShotKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        if (boundary == null) return null;

        pixelRatio ??= MediaQuery.devicePixelRatioOf(context);
        final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio!);

        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        return byteData?.buffer.asUint8List();
      });
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return null;
    }
  }
}
