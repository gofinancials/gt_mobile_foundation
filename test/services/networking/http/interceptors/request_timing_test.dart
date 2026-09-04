import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class _CapturingAnalytics implements AppAnalyticsService {
  final events = <AppAnalyticsData>[];
  @override
  Future<void> trackEvent(AppAnalyticsData data) async => events.add(data);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Session implements AppSessionService {
  _Session(this.shouldBeRefreshed);
  @override
  final bool shouldBeRefreshed;
  @override
  bool get hasToken => true;
  @override
  String? get accessToken => 'token';
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Stub implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future? c) async {
    if (o.path.contains('fail')) throw DioException(requestOptions: o, type: DioExceptionType.connectionError);
    return ResponseBody.fromString('{"ok":true}', 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAnalytics analytics;

  setUp(() {
    analytics = _CapturingAnalytics();
    if (locator.isRegistered<AppAnalyticsService>()) {
      locator.unregister<AppAnalyticsService>();
    }
    locator.registerSingleton<AppAnalyticsService>(analytics);
  });

  Dio build({bool refresh = false, Duration renewTakes = Duration.zero}) =>
      Dio(BaseOptions(baseUrl: 'https://stub.test'))
        ..httpClientAdapter = _Stub()
        ..interceptors.addAll([
          const LoggerInterceptor(),
          JwtInterceptor(_Session(refresh), onRenew: () async {
            await Future<void>.delayed(renewTakes);
            return 'renewed';
          }),
        ]);

  AppAnalyticsData eventFor(AppEvent e) =>
      analytics.events.firstWhere((it) => it.event == e);

  test('a successful response reports its total duration', () async {
    await build().get('/ping');
    final data = eventFor(AppEvent.apiResponse);
    expect(data.duration, isNotNull);
    expect(data.toJson()['durationMs'], isA<int>());
  });

  test('a failed request reports duration too', () async {
    await build().get('/fail').catchError((_) => Response(requestOptions: RequestOptions()));
    final data = eventFor(AppEvent.apiError);
    expect(data.duration, isNotNull, reason: 'errors must be timed, not just successes');
  });

  test('a slow token refresh is attributed to its own phase', () async {
    await build(refresh: true, renewTakes: const Duration(milliseconds: 250)).get('/ping');
    final data = eventFor(AppEvent.apiResponse);
    final json = data.toJson();

    expect(json['renewMs'], isA<int>(), reason: 'renew leg must be attributable');
    // Loose bounds on purpose: this asserts the wiring, not the clock.
    expect(json['renewMs'] as int, greaterThanOrEqualTo(150));
    expect(
      data.duration!.inMilliseconds + 1,
      greaterThanOrEqualTo(json['renewMs'] as int),
      reason: 'total must contain the phase it is built from',
    );
  });

  test('no phase is reported when the refresh does not run', () async {
    await build().get('/ping');
    expect(eventFor(AppEvent.apiResponse).toJson().containsKey('renewMs'), isFalse);
  });
}
