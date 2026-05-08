/// {@category Services}
/// The interface definition for crash reporting and error tracking services.
abstract class AppCrashlyticsService {
  /// Initializes the crashlytics service.
  Future<void> init();

  /// Tracks a non-fatal or fatal error with a [message], optional [error] object, and [trace].
  trackError(String message, {Object? error, StackTrace? trace, bool fatal});

  /// Associates subsequent crash reports with a specific user [id], [email], and optional [name].
  identifyUser({required dynamic id, required String email, String? name});
}
