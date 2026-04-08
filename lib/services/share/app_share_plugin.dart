import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class AppSharePlugin {
  static Rect _getContextRect(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }

  static shareText(
    BuildContext context, {
    String? title,
    required String text,
  }) {
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: title,
        sharePositionOrigin: _getContextRect(context),
      ),
    );
  }

  static shareFile(
    BuildContext context, {
    String? title,
    String? fileName,
    String? mimeType,
    required Uint8List data,
  }) {
    SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(data, mimeType: mimeType ?? "application/pdf")],
        fileNameOverrides: [fileName ?? "transcribr_file"],
        title: title,
        sharePositionOrigin: _getContextRect(context),
      ),
    );
  }
}
