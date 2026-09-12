import 'package:dio/dio.dart';

/// {@category Data}
/// Represents the configuration and state for the application's HTTP client.
final class AppHttpModel {
  late final Dio http;
  final String baseUrl;
  final Map<String, String> headers;
  final String contentType;
  final List<Interceptor> interceptors;
  final Duration timeout;
  static const defaultHeaders = {'Accept': "application/json"};
  static const defaultContentType = "application/json";

  BaseOptions get baseOptions => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: timeout,
    receiveTimeout: timeout,
    sendTimeout: timeout,
    headers: headers,
    contentType: contentType,
  );

  AppHttpModel(
    this.baseUrl, {
    this.interceptors = const [],
    this.headers = defaultHeaders,
    this.contentType = defaultContentType,
    this.timeout = const Duration(minutes: 1),
  }) {
    http = Dio(baseOptions)
      ..transformer = BackgroundTransformer()
      ..interceptors.addAll(interceptors);
  }
}
