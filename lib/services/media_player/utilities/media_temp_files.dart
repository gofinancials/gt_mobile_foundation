import 'dart:io';
import 'dart:typed_data';

import 'package:gt_mobile_foundation/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Writes in-memory media to temporary files that platform players can read.
///
/// `video_player` only plays assets, files and URLs, so [MediaSource.create]
/// copies in-memory media here and the owning [VideoPlayerService] deletes the
/// copy when it is disposed.
///
/// Security review (CWE-73): callers cannot choose the destination path. Names
/// are generated from a fixed prefix, a timestamp and a counter, plus an
/// optional extension restricted to [AppRegex.fileExtensionRegex]. Each name
/// must match [AppRegex.portableFileNameRegex], must not match
/// [AppRegex.windowsReservedFileNameRegex], and the normalized path must remain
/// inside the app's temporary directory. Files are created exclusively, so an
/// existing entry at the path is never reused, and [delete] only removes
/// regular files with the generated prefix inside that directory.
abstract final class AppMediaTempFiles {
  static const _prefix = "gt_media_";
  static int _counter = 0;

  /// Writes [bytes] to a new temporary file and returns it.
  ///
  /// [extension] is given without the leading dot and helps platform players
  /// detect the format. It is dropped unless it matches
  /// [AppRegex.fileExtensionRegex].
  static Future<File> write(Uint8List bytes, {String? extension}) async {
    final directory = await getTemporaryDirectory();
    final file = _childFile(directory, _fileName(extension));
    await file.create(exclusive: true);
    return file.writeAsBytes(bytes, flush: true);
  }

  /// Deletes [file] if it is a temporary media file created by [write].
  ///
  /// Any other path is left untouched.
  static Future<void> delete(File file) async {
    try {
      final name = p.basename(file.path);
      if (!name.startsWith(_prefix)) return;

      final target = _childFile(await getTemporaryDirectory(), name);
      if (p.normalize(file.absolute.path) != target.path) return;

      final type = FileSystemEntity.typeSync(target.path, followLinks: false);
      if (type != FileSystemEntityType.file) return;

      await target.delete();
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  static String _fileName(String? extension) {
    final ext = extension?.toLowerCase();
    final suffix = ext != null && AppRegex.fileExtensionRegex.hasMatch(ext)
        ? ".$ext"
        : "";
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return "$_prefix${stamp}_${_counter++}$suffix";
  }

  static File _childFile(Directory directory, String fileName) {
    if (!AppRegex.portableFileNameRegex.hasMatch(fileName) ||
        AppRegex.windowsReservedFileNameRegex.hasMatch(fileName)) {
      throw FileSystemException(
        "Media temp file name must be a single portable filename.",
        fileName,
      );
    }

    final root = p.normalize(directory.absolute.path);
    final path = p.normalize(p.join(root, fileName));
    if (!p.isWithin(root, path)) {
      throw FileSystemException(
        "Media temp file must remain inside the temporary directory.",
        path,
      );
    }
    return File(path);
  }
}
