import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// Represents the result of a remote task (success or failure).
sealed class TaskResponse<T> extends Equatable {}

/// A successful [TaskResponse] containing the payload [data] of type [T].
class TaskSuccess<T> extends TaskResponse<T> {
  final T data;
  TaskSuccess({required this.data});

  @override
  List<Object?> get props => [data];
}

/// A failed [TaskResponse] containing the [error] details.
class TaskFailure<T> extends TaskResponse<T> {
  final TaskError error;
  TaskFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Encapsulates the details of a task failure, including a human-readable [message],
/// an HTTP [statusCode] (defaulting to 500), and the raw [error] object.
class TaskError extends Equatable {
  final String message;
  final String statusCode;
  final dynamic error;

  const TaskError({required this.message, this.statusCode = "500", this.error});

  @override
  List<Object?> get props => [message, statusCode, error.hashCode];
}

/// A sentinel class representing the absence of a response.
final class NoResponse extends Equatable {
  const NoResponse();

  @override
  List<Object?> get props => [hashCode];
}

/// Convenience extensions on [TaskResponse] for easier state checking and data retrieval.
extension TaskResponseExtension<T> on TaskResponse<T> {
  /// Returns `true` if this response is a [TaskSuccess].
  bool get isSuccess => this is TaskSuccess<T>;

  /// Returns `true` if this response is a [TaskFailure].
  bool get isFailure => this is TaskFailure<T>;

  /// Retrieves the data payload if this is a [TaskSuccess], otherwise returns `null`.
  T? get data {
    if (isFailure) return null;
    return (this as TaskSuccess<T>).data;
  }

  /// Retrieves the [TaskError] if this is a [TaskFailure], otherwise returns `null`.
  TaskError? get error {
    if (!isFailure) return null;
    return (this as TaskFailure<T>).error;
  }

  /// Checks whether the response contains valid data.
  ///
  /// Returns `false` if the task failed or if the data is null.
  /// If the data is an [Iterable] or a [String], it also checks whether it is empty.
  bool get hasData {
    if (isFailure) return false;
    final isNotNull = data != null;
    bool isNotEmpty = true;

    if (data is Iterable) {
      isNotEmpty = (data as Iterable).hasValue;
    }

    if (data is String) {
      isNotEmpty = (data as String).trim().hasValue;
    }

    return isNotEmpty && isNotNull;
  }

  /// Retrieves the error message if this is a [TaskFailure], otherwise returns `null`.
  String? get errorMessage {
    if (!isFailure) return null;
    final error = (this as TaskFailure<T>).error;
    return error.message;
  }
}
