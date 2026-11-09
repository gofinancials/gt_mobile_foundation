import 'package:flutter/services.dart';
import 'package:gt_device_integrity/src/gt_attestation_result.dart';

export 'src/gt_attestation_result.dart';

/// What the device says about itself.
///
/// Every field is a measurement, not a judgement: gt_mobile_foundation decides
/// which signals block the app. A field is null where the platform cannot
/// measure it.
///
/// Every reading is taken inside the app's own process, so a device that
/// hooks the app (with Frida, say) can make every one of them read false. The
/// readings raise the cost of an attack; only an attestation token verified by
/// a server makes the result hold. See [GtDeviceIntegrity.attest].
class GtDeviceIntegrityReport {
  const GtDeviceIntegrityReport({
    required this.platform,
    required this.packageName,
    required this.rooted,
    required this.emulator,
    this.cloneEnvironment,
    this.processNameMismatch,
    this.testKeys,
    this.developerMode,
    this.installer,
    this.signature,
    this.iosAppOnMac,
    this.frida,
    this.hookingFramework,
    this.debuggerAttached,
    this.instrumentationEvidence,
  });

  factory GtDeviceIntegrityReport.fromMap(Map<String, Object?> map) {
    return GtDeviceIntegrityReport(
      platform: map['platform'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      rooted: map['rooted'] == true,
      emulator: map['emulator'] == true,
      cloneEnvironment: map['cloneEnvironment'] as bool?,
      processNameMismatch: map['processNameMismatch'] as bool?,
      testKeys: map['testKeys'] as bool?,
      developerMode: map['developerMode'] as bool?,
      installer: map['installer'] as String?,
      signature: map['signature'] as String?,
      iosAppOnMac: map['iosAppOnMac'] as bool?,
      frida: map['frida'] as bool?,
      hookingFramework: map['hookingFramework'] as bool?,
      debuggerAttached: map['debuggerAttached'] as bool?,
      instrumentationEvidence: _strings(map['instrumentationEvidence']),
    );
  }

  /// `android` or `ios`.
  final String platform;

  /// The application ID (Android) or bundle identifier (iOS).
  final String packageName;

  /// Rooted (Android: su binaries, Magisk, test-keys) or jailbroken (iOS:
  /// jailbreak files, or a write outside the sandbox that succeeds). Always
  /// false on the iOS simulator and for an iPhone app on a Mac, whose system
  /// files would otherwise read as a jailbreak; see [iosAppOnMac].
  final bool rooted;

  /// An Android emulator or the iOS simulator.
  final bool emulator;

  /// Android: running inside a cloning app (a parallel-space sandbox path, a
  /// nested sandbox, or a renamed process). A cloning app merely being
  /// installed is not counted.
  final bool? cloneEnvironment;

  /// Android: the process name differs from [packageName]. Also counted in
  /// [cloneEnvironment]; reported alone for diagnostics.
  final bool? processNameMismatch;

  /// Android: the system image is signed with test keys. Also counted in
  /// [rooted]; reported alone for diagnostics.
  final bool? testKeys;

  /// Android: Developer options are switched on.
  final bool? developerMode;

  /// Android: the package that installed the app (`com.android.vending` for
  /// Google Play), or null when Android does not say, as for a sideload.
  final String? installer;

  /// Android: SHA-256 of the first signing certificate, upper-case hex.
  final String? signature;

  /// iOS: an iPhone app running on an Apple Silicon Mac.
  final bool? iosAppOnMac;

  /// Frida is in the process or listening for it.
  ///
  /// Android: `frida` or `gum-js-loop` in `/proc/self/maps`, a Frida thread
  /// name (`gum-js-loop`, `pool-frida`, `linjector`), or a
  /// listener on 127.0.0.1:27042. iOS: a Frida library among the loaded
  /// images, or the same listener.
  ///
  /// 27042 is the default port of `frida-server` and of Frida Gadget in its
  /// default listen mode. A server moved to another port, or a gadget in
  /// script mode, opens nothing there, so the in-process checks matter more.
  final bool? frida;

  /// A hooking framework is loaded into the process.
  ///
  /// Android: Xposed, EdXposed, LSPosed or LSPatch in `/proc/self/maps`, or
  /// Xposed classes on the stack or loadable. iOS: Substrate, libhooker,
  /// Substitute, ElleKit or TweakInject among the loaded images, or
  /// `DYLD_INSERT_LIBRARIES` set.
  final bool? hookingFramework;

  /// A debugger is attached. Android: `Debug.isDebuggerConnected()` or a
  /// non-zero `TracerPid`. iOS: the process is `P_TRACED`. Running from
  /// Android Studio or Xcode attaches one.
  final bool? debuggerAttached;

  /// What raised [frida], [hookingFramework] or [debuggerAttached], for
  /// diagnostics: for example `maps:frida-agent` or `port:27042`. Empty when
  /// nothing was found.
  final List<String>? instrumentationEvidence;

  Map<String, Object?> toMap() => {
    'platform': platform,
    'packageName': packageName,
    'rooted': rooted,
    'emulator': emulator,
    'cloneEnvironment': cloneEnvironment,
    'processNameMismatch': processNameMismatch,
    'testKeys': testKeys,
    'developerMode': developerMode,
    'installer': installer,
    'signature': signature,
    'iosAppOnMac': iosAppOnMac,
    'frida': frida,
    'hookingFramework': hookingFramework,
    'debuggerAttached': debuggerAttached,
    'instrumentationEvidence': instrumentationEvidence,
  };

  static List<String>? _strings(Object? value) {
    if (value is! List) return null;

    return value.whereType<String>().toList();
  }
}

/// Asks the platform for a [GtDeviceIntegrityReport] or an attestation token.
class GtDeviceIntegrity {
  const GtDeviceIntegrity({
    MethodChannel channel = const MethodChannel('gt_device_integrity'),
  }) : _channel = channel;

  final MethodChannel _channel;

  /// Reads the device. Throws [MissingPluginException] on a platform without
  /// an implementation, [PlatformException] if the platform fails, and
  /// [FormatException] if the answer names no platform (an empty answer, as a
  /// hooked channel might give, is not a clean device). The caller chooses
  /// whether that fails open.
  Future<GtDeviceIntegrityReport> report() async {
    final map = await _channel.invokeMapMethod<String, Object?>('report');
    final platform = map?['platform'];
    final hasPlatform = platform is String && platform.isNotEmpty;

    if (map == null || !hasPlatform) {
      throw const FormatException('Device integrity report names no platform');
    }

    return GtDeviceIntegrityReport.fromMap(map);
  }

  /// Gets the platform ready to produce tokens, and returns null when it is.
  ///
  /// Android: prepares the Play Integrity standard token provider, which can
  /// take a few seconds, so call it early (at app start). It needs
  /// [cloudProjectNumber]. iOS: checks that App Attest is supported.
  ///
  /// Calling it is optional: [attestationToken] prepares on first use.
  Future<GtAttestationProblem?> prepareAttestation({
    int? cloudProjectNumber,
  }) async {
    final arguments = {'cloudProjectNumber': cloudProjectNumber};
    final map = await _call('prepareAttestation', arguments);
    final isReady = map['status'] == 'ready';

    if (isReady) return null;

    final result = GtAttestationResult.fromMap(map);

    if (result is GtAttestationProblem) return result;

    return const GtAttestationFailed('malformed_result');
  }

  /// The one-off, stronger check: binds a token to [challenge], a single-use
  /// value the server issued.
  ///
  /// Android: a classic Play Integrity request whose nonce is the URL-safe,
  /// padded base64 of SHA-256([challenge]). Classic requests are slower and
  /// rate-limited, so use this for registration or login, not every request.
  ///
  /// iOS: generates a new App Attest key and attests it with a client data
  /// hash of SHA-256([challenge]). The key ID is kept in the Keychain (this
  /// device only) once the attestation succeeds, and is returned as
  /// [GtAttestationToken.keyId]; the server stores the key's public key from
  /// the attestation. Each call replaces the key, so call it once per
  /// install, and again after `key_invalidated`.
  ///
  /// The server reproduces the same SHA-256 to check the binding.
  Future<GtAttestationResult> attest({
    required String challenge,
    int? cloudProjectNumber,
  }) async {
    final arguments = {
      'challenge': challenge,
      'cloudProjectNumber': cloudProjectNumber,
    };

    final map = await _call('attest', arguments);

    return GtAttestationResult.fromMap(map);
  }

  /// The per-request check: binds a token to [data], the request being made
  /// (for example a transfer's canonical body).
  ///
  /// Android: a standard Play Integrity request whose request hash is the
  /// URL-safe, padded base64 of SHA-256([data]). Needs
  /// [cloudProjectNumber].
  ///
  /// iOS: an App Attest assertion with the attested key and a client data
  /// hash of SHA-256([data]). Fails with `attestation_required` until
  /// [attest] has succeeded on this install.
  Future<GtAttestationResult> attestationToken({
    required String data,
    int? cloudProjectNumber,
  }) async {
    final arguments = {'data': data, 'cloudProjectNumber': cloudProjectNumber};

    final map = await _call('attestationToken', arguments);

    return GtAttestationResult.fromMap(map);
  }

  Future<Map<String, Object?>> _call(
    String method,
    Map<String, Object?> arguments,
  ) async {
    final reply = _channel.invokeMapMethod<String, Object?>(method, arguments);
    final map = await reply;

    return map ?? const {};
  }
}
