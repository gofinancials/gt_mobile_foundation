import 'package:url_launcher/url_launcher.dart' as ul;
import 'package:url_launcher/url_launcher_string.dart';

class AppUrlHandler {
  static Future<void> openUrl(String url) async {
    if (!await canLaunchUrlString(url)) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    ul.launchUrl(uri);
  }
}
