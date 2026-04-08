import 'package:file_picker/file_picker.dart';

enum FSErrorType { unknown, oversized, empty }

enum FSDocumentType {
  image(FileType.image),
  document(FileType.custom);

  const FSDocumentType(this.type);
  final FileType type;

  List<String>? get extensions {
    return switch (type) {
      .custom => ["pdf", "doc", "docx"],
      _ => null,
    };
  }
}
