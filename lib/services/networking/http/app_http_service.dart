import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

typedef DioResponse = ApiResponse<Response>;

/// Key used to store request sensitivity metadata in Dio's `extra` map.
const sensitiveRequestExtraKey = "IS_SENSITIVE_REQUEST";

/// Key used to store the request's start timestamp in Dio's `extra` map.
const requestStartExtraKey = "REQUEST_STARTED_AT_MICROS";

/// Key used to accumulate per-phase durations in Dio's `extra` map.
const requestPhasesExtraKey = "REQUEST_PHASE_DURATIONS_MS";

/// {@category Services}
/// Records how long a request spends in the client, and in which phase.
///
/// Timings ride along in Dio's `extra` map so a single analytics event can
/// carry the total alongside its breakdown. `RequestOptions.copyWith` shallow
/// copies `extra`, so the phase map is shared by reference across copies and
/// keeps accumulating through the chain.
extension RequestTimingExtension on RequestOptions {
  /// Records the moment this request entered the interceptor chain.
  ///
  /// Called by [LoggerInterceptor], which should therefore be registered first
  /// if the total is to include every other interceptor.
  void markStarted() {
    extra[requestStartExtraKey] = DateTime.now().microsecondsSinceEpoch;
    extra[requestPhasesExtraKey] = <String, int>{};
  }

  /// Wall-clock time since [markStarted], or `null` if it was never called.
  Duration? get elapsed {
    final startedAt = extra[requestStartExtraKey];
    if (startedAt is! int) return null;
    return Duration(
      microseconds: DateTime.now().microsecondsSinceEpoch - startedAt,
    );
  }

  /// Attributes [duration] to a named [phase] of this request.
  void recordPhase(String phase, Duration duration) {
    final existing = extra[requestPhasesExtraKey];
    final phases = existing is Map<String, int> ? existing : <String, int>{};
    // Retries and redirects can run a phase more than once; keep the total.
    phases[phase] = (phases[phase] ?? 0) + duration.inMilliseconds;
    extra[requestPhasesExtraKey] = phases;
  }

  /// Per-phase durations in milliseconds recorded so far.
  Map<String, int>? get recordedPhases {
    final phases = extra[requestPhasesExtraKey];
    if (phases is! Map<String, int> || phases.isEmpty) return null;
    return phases;
  }
}

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
