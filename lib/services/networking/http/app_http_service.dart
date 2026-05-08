import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

abstract class AppHttpService {
  AppHttpService(this._httpModel);
  final AppHttpModel _httpModel;

  Dio get _http => _httpModel.http;

  FormData generateFormData(Map<String, dynamic> data) {
    return FormData.fromMap(data);
  }

  attachInterceptor(Interceptor interceptor) {
    _http.interceptors.tryAdd(interceptor);
  }

  attachInterceptors(List<Interceptor> interceptors) {
    _http.interceptors.addAll(interceptors);
  }

  Future<Response> get(
    String path, {
    Codable? query,
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _http.get(
      path,
      queryParameters: query?.toJson(),
      options: options,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response> download(
    String path, {
    ProgressCallback? onReceiveProgress,
    Codable? query,
    Options? options,
  }) async {
    return await _http.get(
      path,
      queryParameters: query?.toJson(),
      onReceiveProgress: onReceiveProgress,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    Codable? query,
    Codable? body,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _http.put(
      path,
      data: body?.toJson(),
      queryParameters: query?.toJson(),
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response> patch(
    String path, {
    Codable? query,
    Codable? body,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _http.patch(
      path,
      data: body?.toJson(),
      queryParameters: query?.toJson(),
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response> post(
    String path, {
    Codable? query,
    Codable? body,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _http.post(
      path,
      data: body?.toJson(),
      queryParameters: query?.toJson(),
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response> postFile(
    String path, {
    Codable? query,
    FormData? body,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _http.post(
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
    );
  }

  Future<Response> delete(
    String path, {
    Codable? query,
    Codable? body,
    Options? options,
  }) {
    return _http.delete(
      path,
      data: body?.toJson(),
      queryParameters: query?.toJson(),
      options: options,
    );
  }
}
