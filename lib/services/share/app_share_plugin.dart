import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';

/// {@category Services}
/// A plugin for sharing text and files using the `share_plus` package.
class AppSharePlugin {
  static Rect _getContextRect(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }

  /// Shares a simple [text] snippet to the device's native share sheet.
  /// An optional [title] can be provided for email subjects or similar contexts.
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

  /// Shares file [data] to the device's native share sheet.
  ///
  /// [text] is sent along with the file (e.g. as a message caption), while
  /// [title] is only used as the share sheet's title where supported.
  ///
  /// When [mimeType] is omitted it is inferred from [data]'s magic bytes, then
  /// from [fileName]'s extension, falling back to `application/octet-stream`.
  /// When [fileName] is omitted it defaults to `file.<ext>`, with the extension
  /// derived from the resolved MIME type.
  static shareFile(
    BuildContext context, {
    String? title,
    String? text,
    String? fileName,
    String? mimeType,
    required Uint8List data,
  }) {
    final resolvedMimeType =
        mimeType ??
        lookupMimeType(fileName ?? "", headerBytes: data) ??
        "application/octet-stream";

    SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(data, mimeType: resolvedMimeType)],
        fileNameOverrides: [
          fileName ?? "file.${extensionFromMime(resolvedMimeType) ?? "bin"}",
        ],
        title: title,
        // share_plus throws on empty text, so treat it as absent.
        text: text?.isNotEmpty == true ? text : null,
        sharePositionOrigin: _getContextRect(context),
      ),
    );
  }
}
