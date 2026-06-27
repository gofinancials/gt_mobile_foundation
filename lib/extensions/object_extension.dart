import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Extensions}
/// Extension on [Object] that provides global getters for accessing
/// the main configuration and localized strings.
extension ObjectExtension on Object {
  /// Provides quick access to the injected [AppConfig] instance.
  AppConfig get config => locator<AppConfig>();

  /// Provides quick access to the [AppConfigStrings] from the config.
  AppConfigStrings get stringKeys => config.strings;
}

/// Extension on [Response] to provide a convenient method for copying and updating response data.
extension ResponseExtension on Response {
  /// Returns a new [Response] instance with the specified properties updated.
  /// Any property not provided will default to the value from the current instance.
  Response copyWith({
    dynamic data,
    RequestOptions? requestOptions,
    int? statusCode,
    String? statusMessage,
    bool? isRedirect,
    List<RedirectRecord>? redirects,
    Map<String, dynamic>? extra,
    Headers? headers,
  }) {
    return Response(
      data: data ?? this.data,
      requestOptions: requestOptions ?? this.requestOptions,
      statusCode: statusCode ?? this.statusCode,
      statusMessage: statusMessage ?? this.statusMessage,
      isRedirect: isRedirect ?? this.isRedirect,
      redirects: redirects ?? this.redirects,
      extra: extra ?? this.extra,
      headers: headers ?? this.headers,
    );
  }

  /// Creates an [ApiResponse] from a Dio [Response] object.
  ///
  /// Automatically unwraps JSON maps using [ApiResponse.fromJson] while passing
  /// the HTTP status code and message as fallbacks.
  ApiResponse<Response> get asApiResponse {
    final code = statusCode.toString();
    final message = statusMessage;

    return switch (data) {
      Map data => ApiResponse.fromJson(
        data,
        defaultCode: code,
        defaultMessage: message,
        rawResponse: this,
      ),
      dynamic data => ApiResponse(
        responseCode: code,
        message: message,
        data: data,
        rawResponse: this,
      ),
    };
  }
}
