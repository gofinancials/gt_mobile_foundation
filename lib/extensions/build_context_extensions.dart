import 'package:easy_localization/easy_localization.dart'
    hide StringTranslateExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

extension BuildContextExtension on BuildContext {
  ScrollableState? get scrollState => Scrollable.maybeOf(this);

  copyTextToClipboard(String? value, {String? message}) {
    if (!value.hasValue) return;
    Clipboard.setData(ClipboardData(text: value!));
  }

  Future<String?> getClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      return null;
    }
  }

  resetFocus() => requestFocus(FocusNode());

  requestFocus(FocusNode node) {
    FocusScope.of(this).requestFocus(node);
  }

  TargetPlatform get _platform {
    return Theme.of(this).platform;
  }

  launchUrl(String url) {
    try {
      AppUrlHandler.openUrl(url);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  bool get isIos => _platform == TargetPlatform.iOS;

  bool get isAndroid => _platform == TargetPlatform.android;

  bool get isFucshia => _platform == TargetPlatform.fuchsia;

  bool get isLinux => _platform == TargetPlatform.linux;

  bool get isWindows => _platform == TargetPlatform.windows;

  bool get isMacos => _platform == TargetPlatform.macOS;

  updateLocale(Locale locale) {
    AppTextFormatter.locale = locale;
    setLocale(locale);
  }

  Locale get currentLocale {
    return locale;
  }

  String get currentLocaleString {
    return "$locale";
  }

  List<Locale> get locales {
    return supportedLocales;
  }

  shareText(String text, {String? title}) {
    AppSharePlugin.shareText(this, text: text, title: title);
  }

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

  makeVisible() {
    Scrollable.ensureVisible(
      this,
      alignment: .5,
      duration: 300.milliseconds,
      curve: Curves.decelerate,
    );
  }
}
