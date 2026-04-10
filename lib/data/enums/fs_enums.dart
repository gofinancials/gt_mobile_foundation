import 'package:file_picker/file_picker.dart';

enum FsErrorType { unknown, oversized, empty }

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
