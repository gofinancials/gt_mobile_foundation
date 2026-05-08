import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A mock implementation of [AppCrashlyticsService] that logs errors to the console.
class AppCrashlyticsMockService implements AppCrashlyticsService {
  @override
  Future init() async {}

  @override
  trackError(
    String message, {
    Object? error,
    StackTrace? trace,
    bool fatal = false,
  }) {
    AppLogger.severe(message, error: error, stackTrace: trace);
  }

  @override
  identifyUser({required id, required String email, String? name}) {
    AppLogger.info("ID -> $id; EMAIL -> $email; NAME -> ${name ?? 'no-name'}");
  }
}
