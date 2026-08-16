import 'package:gt_mobile_foundation/foundation.dart';

/// The Composite Facade implementation of [AppAnalyticsService].
///
/// Holds a collection of [AnalyticsProvider] adapters and broadcasts all
/// analytics calls (user identification, event logging, navigation tracking)
/// to all registered providers.
class AppAnalyticsServiceImpl implements AppAnalyticsService {
  final List<AnalyticsProvider> _providers;

  /// Creates a new [AppAnalyticsServiceImpl] with an optional initial list of [_providers].
  AppAnalyticsServiceImpl([List<AnalyticsProvider>? providers])
    : _providers = List<AnalyticsProvider>.from(providers ?? []);

  /// List of currently registered analytics providers.
  List<AnalyticsProvider> get providers => List.unmodifiable(_providers);

  @override
  void addProvider(AnalyticsProvider provider) {
    if (!_providers.contains(provider)) {
      _providers.add(provider);
    }
  }

  @override
  void removeProvider(AnalyticsProvider provider) {
    _providers.remove(provider);
  }

  @override
  Future<void> initialize() async {
    await Future.wait(_providers.map((p) => p.initialize()));
  }

  @override
  Future<void> identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  }) async {
    await Future.wait(
      _providers.map(
        (p) => p.identifyUser(
          id: id,
          accountNumber: accountNumber,
          name: name,
          email: email,
          telephone: telephone,
          bvn: bvn,
        ),
      ),
    );
  }

  @override
  Future<void> trackEvent(AppAnalyticsData eventData) async {
    await Future.wait(_providers.map((p) => p.trackEvent(eventData)));
  }

  @override
  Future<void> trackNavigation(String path, {String? widgetClass}) async {
    await Future.wait(
      _providers.map((p) => p.trackNavigation(path, widgetClass: widgetClass)),
    );
  }
}
