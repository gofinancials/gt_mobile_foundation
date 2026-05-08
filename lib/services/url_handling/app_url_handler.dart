import 'package:url_launcher/url_launcher.dart' as ul;
import 'package:url_launcher/url_launcher_string.dart';

/// {@category Services}
/// A utility class for handling URL launching operations.
class AppUrlHandler {
  /// Opens the given [url] in the device's default browser or associated application.
  static Future<void> openUrl(String url) async {
    if (!await canLaunchUrlString(url)) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    ul.launchUrl(uri);
  }
}
