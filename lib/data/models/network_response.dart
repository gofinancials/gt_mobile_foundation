import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';

sealed class TaskResponse<T> extends Equatable {}

class TaskSuccess<T> extends TaskResponse<T> {
  final T data;
  TaskSuccess({required this.data});

  @override
  List<Object?> get props => [data];
}

class TaskFailure<T> extends TaskResponse<T> {
  final TaskError error;
  TaskFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class TaskError extends Equatable {
  final String message;
  final int statusCode;
  final dynamic error;

  const TaskError({required this.message, this.statusCode = 500, this.error});

  @override
  List<Object?> get props => [message, statusCode, error.hashCode];
}

final class NoResponse extends Equatable {
  const NoResponse();

  @override
  List<Object?> get props => [hashCode];
}

extension TaskResponseExtension<T> on TaskResponse<T> {
  bool get isSuccess => this is TaskSuccess<T>;
  bool get isFailure => this is TaskFailure<T>;

  T? get data {
    if (isFailure) return null;
    return (this as TaskSuccess<T>).data;
  }

  TaskError? get error {
    if (!isFailure) return null;
    return (this as TaskFailure<T>).error;
  }

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

  String? get errorMessage {
    if (!isFailure) return null;
    final error = (this as TaskFailure<T>).error;
    return error.message;
  }
}
