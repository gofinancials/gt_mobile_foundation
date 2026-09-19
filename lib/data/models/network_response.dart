import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';

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

  /// The gateway's business-success flag, or `null` when it sent none.
  ///
  /// A gateway answers `200` while reporting a refusal in the body, so the
  /// status code alone does not say whether the operation happened. Null is a
  /// third answer, distinct from `false`: the reply reported neither way.
  final bool? isSuccessful;

  /// Creates an [ApiResponse] with the specified [responseCode], [message], and [data].
  const ApiResponse({
    this.responseCode = "200",
    this.message,
    this.data,
    this.rawResponse,
    this.isSuccessful,
  });

  /// Creates a copy of this [ApiResponse] but with the given fields replaced with the new values.
  ApiResponse copyWith({
    String? responseCode,
    String? message,
    dynamic data,
    T? rawResponse,
    bool? isSuccessful,
  }) {
    return ApiResponse(
      responseCode: responseCode ?? this.responseCode,
      message: message ?? this.message,
      data: data ?? this.data,
      rawResponse: rawResponse ?? this.rawResponse,
      isSuccessful: isSuccessful ?? this.isSuccessful,
    );
  }

  /// Creates an [ApiResponse] by extracting fields from a JSON [Map].
  ///
  /// If the JSON does not contain a `"responseCode"` or `"message"`, it falls back to
  /// the [defaultCode] and [defaultMessage] respectively.
  ///
  /// [isSuccessful] is read across the spellings the gateway sends, and stays
  /// null when it sent none. It is read but not acted on here: what a refusal
  /// means belongs to the caller, so [data] is unwrapped either way.
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
      isSuccessful: AppJson.successFlag(AppJson.asMap(json)),
    );
  }

  @override
  List<Object?> get props => [responseCode, message, data, isSuccessful];
}
