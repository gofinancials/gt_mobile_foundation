import 'package:easy_localization/easy_localization.dart'
    hide StringTranslateExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Extensions}
/// Extension on [BuildContext] providing UI utilities, localization access, and device info.
extension BuildContextExtension on BuildContext {
  /// Returns the closest [ScrollableState] ancestor, if any.
  ScrollableState? get scrollState => Scrollable.maybeOf(this);

  /// Copies the provided [value] to the system clipboard.
  copyTextToClipboard(String? value, {String? message}) {
    if (!value.hasValue) return;
    Clipboard.setData(ClipboardData(text: value!));
  }

  /// Asynchronously retrieves the current plain text from the system clipboard.
  Future<String?> getClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      return null;
    }
  }

  /// Resets the current focus scope to an empty, unfocused node.
  resetFocus() => requestFocus(FocusNode());

  /// Requests focus for the specified [node] within this context's scope.
  requestFocus(FocusNode node) {
    FocusScope.of(this).requestFocus(node);
  }

  /// Retrieves the current [TargetPlatform] from the theme.
  TargetPlatform get _platform {
    return Theme.of(this).platform;
  }

  /// Launches a URL using the foundation's central [AppUrlHandler].
  launchUrl(String url) {
    try {
      AppUrlHandler.openUrl(url);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  /// Returns `true` if the current platform is iOS.
  bool get isIos => _platform == TargetPlatform.iOS;

  /// Returns `true` if the current platform is Android.
  bool get isAndroid => _platform == TargetPlatform.android;

  /// Returns `true` if the current platform is Fuchsia.
  bool get isFucshia => _platform == TargetPlatform.fuchsia;

  /// Returns `true` if the current platform is Linux.
  bool get isLinux => _platform == TargetPlatform.linux;

  /// Returns `true` if the current platform is Windows.
  bool get isWindows => _platform == TargetPlatform.windows;

  /// Returns `true` if the current platform is macOS.
  bool get isMacos => _platform == TargetPlatform.macOS;

  /// Updates the application's locale both in `easy_localization` and foundation config.
  updateLocale(Locale locale) {
    AppTextFormatter.locale = locale;
    setLocale(locale);
  }

  /// Returns the current active [Locale].
  Locale get currentLocale {
    return locale;
  }

  /// Returns the string representation of the current active locale (e.g., "en_US").
  String get currentLocaleString {
    return "$locale";
  }

  /// Returns the list of locales supported by the application.
  List<Locale> get locales {
    return supportedLocales;
  }

  /// Shares a plain [text] using the native share dialog.
  shareText(String text, {String? title}) {
    AppSharePlugin.shareText(this, text: text, title: title);
  }

  /// Shares a file via the native share dialog using [Uint8List] raw data.
  shareFile(
    Uint8List data, {
    String? title,
    String? fileName,
    String? mimeType,
  }) {
    AppSharePlugin.shareFile(
      this,
      data: data,
      title: title,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Scrolls the closest scrollable to ensure the widget associated with this context is visible.
  makeVisible() {
    Scrollable.ensureVisible(
      this,
      alignment: .5,
      duration: 300.milliseconds,
      curve: Curves.decelerate,
    );
  }
}
