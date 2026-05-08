import 'package:file_picker/file_picker.dart';

/// {@category Data}
/// Defines errors that can occur during file system operations.
enum FsErrorType { unknown, oversized, empty }

/// {@category Data}
/// Defines the allowed document types for file picking operations.
enum FsDocumentType {
  image(.image),
  document(.custom);

  const FsDocumentType(this.type);
  final FileType type;

  List<String>? get extensions {
    return switch (type) {
      .custom => ["pdf", "doc", "docx"],
      _ => null,
    };
  }
}
