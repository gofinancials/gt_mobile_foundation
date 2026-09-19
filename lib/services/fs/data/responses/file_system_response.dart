import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Represents an error that occurred during a file system operation.
class FsError {
  final FsErrorType type;
  final Object? error;
  final StackTrace? stackTrace;

  const FsError({required this.type, this.error, this.stackTrace});

  bool get isTooLarge => type == .oversized;

  /// Whether no file came back, whether the picker returned nothing or the
  /// user dismissed it. Use [isCancelled] to tell a dismissal apart.
  bool get hasNoFile => type == .empty || type == .cancelled;

  /// Whether the user dismissed the picker or the save dialog.
  ///
  /// A dismissal is a choice rather than a failure, so callers should fall
  /// silent instead of reporting an error.
  bool get isCancelled => type == .cancelled;

  bool get isUnknown => type == .unknown;

  @Deprecated(
    'Reads as "nothing came back" but is also true for a dismissal. '
    'Use hasNoFile for that meaning, or isCancelled for a dismissal alone.',
  )
  bool get isEmpty => hasNoFile;
}

/// {@category Services}
/// Contains the response data from a file system operation, including the file or error.
class FsResponse extends Equatable {
  final File? file;
  final String? name;
  final String? mimeType;
  final FsError? error;
  final FsDocumentType type;

  const FsResponse({
    this.error,
    this.file,
    this.name,
    required this.type,
    this.mimeType,
  });

  bool get hasError => error != null;
  bool get hasFile => file != null;
  bool get isImage => type == .image;

  /// Whether the user dismissed the picker. A dismissal is a choice, not a
  /// failure: callers fall silent rather than reporting it.
  ///
  /// This is narrower than [hasNoSelection], which also covers a pick that
  /// came back with nothing.
  bool get wasCancelled => error?.isCancelled ?? false;

  /// Whether no file came back, dismissal included.
  ///
  /// False for a pick that failed on its own terms — an oversized file was
  /// still selected. Use [wasCancelled] for a dismissal alone.
  bool get hasNoSelection => error?.hasNoFile ?? false;

  Uri? get uri => file?.uri;

  @override
  List<Object?> get props => [file, name, error, type, mimeType];
}
