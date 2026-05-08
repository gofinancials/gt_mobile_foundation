import 'dart:io';

/// {@category Utilities}
/// A custom [HttpOverrides] that bypasses SSL certificate validation.
///
/// **WARNING:** This should only be used in development or controlled testing environments.
/// Using this in production exposes the app to man-in-the-middle (MITM) attacks.
class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => false;
  }
}
