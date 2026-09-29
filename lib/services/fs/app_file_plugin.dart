import 'dart:io';
import 'dart:typed_data';

import 'package:gt_mobile_foundation/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// {@category Services}
/// A plugin for handling file system operations such as picking and saving files.
class AppFilePlugin {
  /// Internal instance of [FilePicker].
  static final FilePicker _picker = FilePicker.platform;

  /// Retrieves the MIME type of the given [file] from its content, falling
  /// back to the extension of [name] (such as a picked file's original name)
  /// and then the file's path.
  /// Falls back to "image/*" if the document type is [FsDocumentType.image] and
  /// nothing specific is found.
  static Future<String?> getFileMimeType(
    File file, {
    FsDocumentType? type,
    String? name,
  }) async {
    try {
      final mimeType = await AppMimeResolver.fromFile(file, name: name);
      if (AppMimeResolver.isGeneric(mimeType) && type == .image) {
        return AppMimeTypes.image;
      }
      return mimeType;
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return null;
    }
  }

  /// Calculates the maximum allowed file size in MB based on [mimeType] and user subscription tier.
  static int getMaxSizeInMb(String mimeType) {
    final mime = mimeType.lower;
    if (mime.startsWith("image")) return 5;
    return 200;
  }

  /// Builds the response for a picked [choiceFile], typed from its content
  /// and checked against the size limit for that type.
  static Future<FsResponse> _response(
    PlatformFile choiceFile,
    FsDocumentType documentType,
  ) async {
    try {
      final path = choiceFile.path;
      if (path == null) {
        return FsResponse(
          type: documentType,
          error: const FsError(type: .empty),
        );
      }

      final File file = File(path);
      final mimeType = await getFileMimeType(
        file,
        type: documentType,
        name: choiceFile.name,
      );
      final maxSizeInMb = getMaxSizeInMb(mimeType ?? "");

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
    } catch (e, t) {
      return FsResponse(
        error: FsError(type: .unknown, error: e, stackTrace: t),
        type: documentType,
      );
    }
  }

  /// Opens the device's native file picker to let the user select a file.
  /// Validates file size against limits based on the user's tier.
  static Future<FsResponse> pickFile({
    String? title,
    FsDocumentType documentType = .document,
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
          error: const FsError(type: .cancelled),
        );
      }

      return await _response(pickedFile.files.first, documentType);
    } catch (e, t) {
      return FsResponse(
        error: FsError(type: .unknown, error: e, stackTrace: t),
        type: documentType,
      );
    }
  }

  /// Opens the device's native file picker to let the user select several
  /// files at once.
  ///
  /// Returns one [FsResponse] per picked file, in the order picked. Each file
  /// is checked on its own, so an oversized or unreadable file carries its
  /// own error without affecting the others.
  ///
  /// Returns an empty list when the user dismisses the picker, and a single
  /// [FsErrorType.unknown] response when the picker itself fails.
  static Future<List<FsResponse>> pickFiles({
    String? title,
    FsDocumentType documentType = .document,
  }) async {
    try {
      final pickedFiles = await _picker.pickFiles(
        allowedExtensions: documentType.extensions,
        allowMultiple: true,
        dialogTitle: title,
        type: documentType.type,
        withReadStream: true,
      );

      if (pickedFiles == null) return [];

      return await Future.wait(
        pickedFiles.files.map((file) => _response(file, documentType)),
      );
    } catch (e, t) {
      return [
        FsResponse(
          error: FsError(type: .unknown, error: e, stackTrace: t),
          type: documentType,
        ),
      ];
    }
  }

  /// Saves the provided [bytes] as a new file on the device with the given [filename] and [ext].
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
          error: FsError(type: .cancelled),
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
