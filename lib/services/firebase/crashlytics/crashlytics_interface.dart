abstract class AppCrashlyticsService {
  Future<void> init();
  trackError(String message, {Object? error, StackTrace? trace, bool fatal});
  identifyUser({required dynamic id, required String email, String? name});
}
