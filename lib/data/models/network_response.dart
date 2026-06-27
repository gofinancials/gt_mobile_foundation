import 'package:equatable/equatable.dart';

/// {@category Data}
/// A standard wrapper for API responses parsed from network requests.
class ApiResponse<T> extends Equatable {
  /// The status or response code representing the outcome of the request.
  final String responseCode;

  /// An optional descriptive message returned by the server.
  final String? message;

  /// The payload data returned by the server.
  final dynamic data;

  final T? rawResponse;

  /// Creates an [ApiResponse] with the specified [responseCode], [message], and [data].
  const ApiResponse({
    this.responseCode = "200",
    this.message,
    this.data,
    this.rawResponse,
  });

  /// Creates a copy of this [ApiResponse] but with the given fields replaced with the new values.
  ApiResponse copyWith({
    String? responseCode,
    String? message,
    dynamic data,
    T? rawResponse,
  }) {
    return ApiResponse(
      responseCode: responseCode ?? this.responseCode,
      message: message ?? this.message,
      data: data ?? this.data,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }

  /// Creates an [ApiResponse] by extracting fields from a JSON [Map].
  ///
  /// If the JSON does not contain a `"responseCode"` or `"message"`, it falls back to
  /// the [defaultCode] and [defaultMessage] respectively.
  factory ApiResponse.fromJson(
    Map json, {
    String? defaultCode,
    String? defaultMessage,
    T? rawResponse,
  }) {
    return ApiResponse(
      responseCode: json["responseCode"] ?? defaultCode ?? "200",
      message: json["message"] ?? defaultMessage,
      data: json["data"] ?? json,
      rawResponse: rawResponse,
    );
  }

  @override
  List<Object?> get props => [responseCode, message, data];
}
