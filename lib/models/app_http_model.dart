import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:dio/dio.dart';

final class AppHttpModel {
  late Dio http;

  Duration get _timeout => 1.minutes;

  AppHttpModel(String baseUrl) {
    http = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        headers: {'Accept': "application/json"},
        contentType: "application/json",
      ),
    )..transformer = BackgroundTransformer();
  }
}
