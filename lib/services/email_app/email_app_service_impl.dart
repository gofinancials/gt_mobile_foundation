import 'package:gt_mobile_foundation/foundation.dart';
import 'package:open_mail_launcher/open_mail_launcher.dart';

/// {@category Services}
/// The standard [AppEmailAppService], over the `open_mail_launcher` package.
class AppEmailAppServiceImpl implements AppEmailAppService {
  /// Creates the service.
  const AppEmailAppServiceImpl();

  /// The id iOS lists the default mail app under. Opening it starts a blank
  /// message instead of showing the inbox, so it is left out.
  static const _composeId = 'mailto:';

  @override
  Future<List<AppEmailApp>> emailApps() async {
    try {
      final apps = await OpenMailLauncher.getMailApps();
      return [
        for (final app in apps)
          if (app.id != _composeId) AppEmailApp(id: app.id, name: app.name),
      ];
    } catch (e, t) {
      AppLogger.severe(
        'Email apps could not be listed',
        error: e,
        stackTrace: t,
      );
      return const [];
    }
  }

  @override
  Future<bool> open(AppEmailApp app) async {
    try {
      return await OpenMailLauncher.openSpecificMailApp(
        mailApp: MailApp(id: app.id, name: app.name),
      );
    } catch (e, t) {
      AppLogger.severe(
        '${app.name} could not be opened',
        error: e,
        stackTrace: t,
      );
      return false;
    }
  }
}
