import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

class FSError {
  final FSErrorType type;
  final Object? error;
  final StackTrace? stackTrace;

  const FSError({required this.type, this.error, this.stackTrace});

  bool get isTooLarge => type == FSErrorType.oversized;
  bool get isEmpty => type == FSErrorType.empty;
  bool get isUnknown => type == FSErrorType.unknown;
}

class FSResponse extends Equatable {
  final File? file;
  final String? name;
  final String? mimeType;
  final FSError? error;
  final FSDocumentType type;

  const FSResponse({
    this.error,
    this.file,
    this.name,
    required this.type,
    this.mimeType,
  });

  bool get hasError => error != null;
  bool get hasFile => file != null;
  bool get isImage => type == FSDocumentType.image;

  Uri? get uri => file?.uri;

  @override
  List<Object?> get props => [file, name, error, type, mimeType];
}
