import 'package:gt_mobile_foundation/foundation.dart';
import 'package:dio/dio.dart';

final class AppHttpModel {
  late Dio http;

  Duration get timeout => 1.minutes;

  AppHttpModel(String baseUrl) {
    http = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: {'Accept': "application/json"},
        contentType: "application/json",
      ),
    )..transformer = BackgroundTransformer();
  }
}
