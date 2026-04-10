import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class AppFilePlugin {
  static final FilePicker _picker = FilePicker.platform;

  static Future<String?> getFileMimeType(
    File file, {
    FsDocumentType? type,
  }) async {
    try {
      final mimeType = lookupMimeType(file.path);
      if (!mimeType.hasValue && type != null) {
        return switch (type) {
          .image => "image/*",
          _ => null,
        };
      }
      return mimeType;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return null;
    }
  }

  static int getMaxSizeInMb(String mimeType, bool isProUser) {
    final mime = mimeType.lower;
    if (mime.startsWith("image")) return 5;
    if (!isProUser) return 100;
    return 200;
  }

  static Duration getMaxDuration(String mimeType, bool isProUser) {
    return 1.hours;
  }

  static Future<FsResponse> pickFile({
    String? title,
    FsDocumentType documentType = .document,
    bool isProUser = false,
  }) async {
    try {
      final pickedFile = await _picker.pickFiles(
        allowedExtensions: documentType.extensions,
        dialogTitle: title,
        type: documentType.type,
        withReadStream: true,
      );

      if (pickedFile == null) {
        return FsResponse(
          type: documentType,
          error: const FsError(type: .empty),
        );
      }

      final choiceFile = pickedFile.files.first;

      if (choiceFile.path == null) {
        return FsResponse(
          type: documentType,
          error: const FsError(type: .empty),
        );
      }

      final File file = File(choiceFile.path!);
      final mimeType = await getFileMimeType(file, type: documentType);
      final maxSizeInMb = getMaxSizeInMb(mimeType ?? "", isProUser);

      if (AppHelpers.fileSizeInMb(file) > maxSizeInMb) {
        return FsResponse(
          error: const FsError(type: .oversized),
          type: documentType,
        );
      }
      return FsResponse(
        file: file,
        name: choiceFile.name,
        type: documentType,
        mimeType: mimeType,
      );
    } catch (e) {
      return FsResponse(
        error: const FsError(type: .unknown),
        type: documentType,
      );
    }
  }

  static Future<FsResponse> saveFile(
    Uint8List bytes, {
    required String filename,
    String? dialogTitle,
    required String ext,
    FileType fileType = FileType.any,
  }) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      if (!filename.endsWith(ext)) filename = "$filename.$ext";

      final filePath = await _picker.saveFile(
        bytes: bytes,
        dialogTitle: dialogTitle,
        fileName: filename,
        type: fileType,
        allowedExtensions: [ext],
        initialDirectory: docDir.path,
      );

      if (filePath == null) {
        return const FsResponse(
          type: .document,
          error: FsError(type: .empty),
        );
      }

      return const FsResponse(type: .document);
    } catch (e, t) {
      return FsResponse(
        error: FsError(type: .unknown, error: e, stackTrace: t),
        type: .document,
      );
    }
  }
}
