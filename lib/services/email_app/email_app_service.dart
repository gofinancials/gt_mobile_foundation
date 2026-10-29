/// {@category Services}
/// Lists the mail apps on the device and opens one at its inbox.
abstract class AppEmailAppService {
  /// The mail apps installed on this device, empty when there are none.
  Future<List<AppEmailApp>> emailApps();

  /// Opens [app] at its inbox. False when it could not be opened.
  Future<bool> open(AppEmailApp app);
}

/// {@category Services}
/// A mail app installed on the device.
class AppEmailApp {
  /// Creates a mail app.
  const AppEmailApp({required this.id, required this.name});

  /// What the platform opens: the package name on Android, the URL on iOS.
  final String id;

  /// The name to show the customer.
  final String name;
}
