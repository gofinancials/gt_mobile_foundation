import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

sealed class NetworkResponse<T> {}

class NetworkSuccess<T> extends NetworkResponse<T> {
  final T data;
  NetworkSuccess({required this.data});
}

class NetworkFailure<T> extends NetworkResponse<T> {
  final NetworkError error;
  NetworkFailure({required this.error});
}

extension NetworkResponseExtension<T> on NetworkResponse<T> {
  bool get isSuccess => this is NetworkSuccess<T>;
  bool get isFailure => this is NetworkFailure<T>;

  T? get data {
    if (isFailure) return null;
    return (this as NetworkSuccess<T>).data;
  }

  NetworkError? get error {
    if (!isFailure) return null;
    return (this as NetworkFailure<T>).error;
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
    final error = (this as NetworkFailure<T>).error;
    return error.message;
  }
}

class NetworkError {
  final String message;
  final int statusCode;
  final dynamic error;

  const NetworkError({
    required this.message,
    this.statusCode = 500,
    this.error,
  });
}

final class NoResponse {
  const NoResponse();
}
