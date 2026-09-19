import 'package:file_picker/file_picker.dart';

/// {@category Data}
/// Defines errors that can occur during file system operations.
///
/// [empty] and [cancelled] both mean no file came back, but only [cancelled]
/// means the user chose that — they dismissed the picker or the save dialog.
/// Callers that report a failure need the difference, because a dismissal is
/// not one.
enum FsErrorType { unknown, oversized, empty, cancelled }

/// {@category Data}
/// Defines the allowed document types for file picking operations.
enum FsDocumentType {
  image(.image),
  document(.custom);

  const FsDocumentType(this.type);
  final FileType type;

  List<String>? get extensions {
    return switch (type) {
      .custom => ["pdf", "doc", "docx", "csv", "xlsx", "pptx"],
      _ => null,
    };
  }
}
