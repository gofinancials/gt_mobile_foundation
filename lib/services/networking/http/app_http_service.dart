import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

typedef DioResponse = ApiResponse<Response>;

/// Key used to store request sensitivity metadata in Dio's `extra` map.
const sensitiveRequestExtraKey = "IS_SENSITIVE_REQUEST";

extension on Options? {
  /// Marks the request as sensitive
  Options markAsSensitive(bool isSensitiveRequest) {
    final options = this ?? Options();
    return options.copyWith(
      extra: {...?options.extra, sensitiveRequestExtraKey: isSensitiveRequest},
    );
  }
}

/// {@category Services}
/// An abstract service wrapper around Dio for executing HTTP requests.
abstract class AppHttpService {
  AppHttpService(this._httpModel);
  final AppHttpModel _httpModel;

  Dio get _http => _httpModel.http;

  /// Generates a `FormData` object from the provided [data] map.
  FormData generateFormData(Map<String, dynamic> data) {
    return FormData.fromMap(data);
  }

  /// Attaches a single [interceptor] to the underlying HTTP client.
  attachInterceptor(Interceptor interceptor) {
    _http.interceptors.tryAdd(interceptor);
  }

  /// Attaches a list of [interceptors] to the underlying HTTP client.
  attachInterceptors(List<Interceptor> interceptors) {
    _http.interceptors.addAll(interceptors);
  }

  /// Executes a GET request to the specified [path] with optional [query] parameters,
  /// custom request [options], and a callback [onReceiveProgress].
  Future<DioResponse> get(
    String path, {
    Codable? query,
    Options? options,
    ProgressCallback? onReceiveProgress,
    bool isSensitiveRequest = false,
  }) {
    return transformToApiResponse(
      _http.get(
        path,
        queryParameters: query?.toJson(),
        options: options.markAsSensitive(isSensitiveRequest),
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  /// Executes a GET request specifically intended for downloading data from the [path].
  Future<DioResponse> download(
    String path, {
    ProgressCallback? onReceiveProgress,
    Codable? query,
    Options? options,
    bool isSensitiveRequest = false,
  }) {
    return transformToApiResponse(
      _http.get(
        path,
        queryParameters: query?.toJson(),
        onReceiveProgress: onReceiveProgress,
        options: options.markAsSensitive(isSensitiveRequest),
      ),
    );
  }

  /// Executes a PUT request to the specified [path] with an optional [body].
  Future<DioResponse> put(
    String path, {
    Codable? query,
    Codable? body,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isSensitiveRequest = false,
  }) {
    return transformToApiResponse(
      _http.put(
        path,
        data: body?.toJson(),
        queryParameters: query?.toJson(),
        options: options.markAsSensitive(isSensitiveRequest),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  /// Executes a PATCH request to the specified [path] with an optional [body].
  Future<DioResponse> patch(
    String path, {
    Codable? query,
    Codable? body,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isSensitiveRequest = false,
  }) {
    return transformToApiResponse(
      _http.patch(
        path,
        data: body?.toJson(),
        queryParameters: query?.toJson(),
        options: options.markAsSensitive(isSensitiveRequest),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  /// Executes a POST request to the specified [path] with an optional [body].
  Future<DioResponse> post(
    String path, {
    Codable? query,
    Codable? body,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool isSensitiveRequest = false,
  }) {
    return transformToApiResponse(
      _http.post(
        path,
        data: body?.toJson(),
        queryParameters: query?.toJson(),
        options: options.markAsSensitive(isSensitiveRequest),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  /// Executes a POST request optimized for file uploads via `multipart/form-data` to the specified [path].
  Future<DioResponse> postFile(
    String path, {
    Codable? query,
    FormData? body,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return transformToApiResponse(
      _http.post(
        path,
        data: body,
        queryParameters: query?.toJson(),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          sendTimeout: 10.minutes,
          receiveTimeout: 10.minutes,
          headers: {Headers.contentTypeHeader: "multipart/form-data"},
        ),
      ),
    );
  }

  /// Executes a DELETE request to the specified [path].
  Future<DioResponse> delete(
    String path, {
    Codable? query,
    Codable? body,
    Options? options,
    bool isSensitiveRequest = false,
  }) {
    return transformToApiResponse(
      _http.delete(
        path,
        data: body?.toJson(),
        queryParameters: query?.toJson(),
        options: options.markAsSensitive(isSensitiveRequest),
      ),
    );
  }

  /// Converts a [Future<Response>] to a [Future<ApiResponse>] by calling
  /// [asApiResponse] on the resolved [Response] object.
  Future<DioResponse> transformToApiResponse(
    Future<Response> responseFuture,
  ) async {
    return (await responseFuture).asApiResponse;
  }
}
