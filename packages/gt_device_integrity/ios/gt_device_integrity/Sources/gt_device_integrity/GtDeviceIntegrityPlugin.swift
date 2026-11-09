import Flutter
import UIKit

/// Reads what the device says about itself. Every entry is a measurement;
/// deciding which ones block the app belongs to gt_mobile_foundation.
///
/// The checks are NewMobileChannel's AppDelegate security channel. iOS cannot
/// read developer mode, the installer, the signature or a clone environment,
/// so those entries are absent rather than guessed. Unlike NMC, an iPhone app
/// on a Mac is reported as such rather than as jailbroken.
///
/// The report is read on a background queue, because the instrumentation
/// probe opens a socket. Attestation goes through `AppAttestation`.
public class GtDeviceIntegrityPlugin: NSObject, FlutterPlugin {
  private let instrumentation = InstrumentationProbe()
  private let attestation = AppAttestation()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gt_device_integrity", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(GtDeviceIntegrityPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]

    switch call.method {
    case "report":
      reportInBackground(result: result)
    case "prepareAttestation":
      attestation.prepare(result: result)
    case "attest":
      attestation.attest(challenge: arguments?["challenge"] as? String, result: result)
    case "attestationToken":
      attestation.token(data: arguments?["data"] as? String, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func reportInBackground(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let answer = self.report()

      DispatchQueue.main.async { result(answer) }
    }
  }

  private func report() -> [String: Any] {
    let readings = instrumentation.read()

    return [
      "platform": "ios",
      "packageName": Bundle.main.bundleIdentifier ?? "",
      "rooted": isJailbroken(),
      "emulator": isSimulator(),
      "iosAppOnMac": isiOSAppOnMac(),
      "frida": readings.frida,
      "hookingFramework": readings.hookingFramework,
      "debuggerAttached": readings.debuggerAttached,
      "instrumentationEvidence": readings.evidence,
    ]
  }

  /// An iPhone app running on an Apple Silicon Mac. It runs the device build,
  /// so the simulator guard does not apply.
  private func isiOSAppOnMac() -> Bool {
    return ProcessInfo.processInfo.isiOSAppOnMac
  }

  private func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
  }

  private func isJailbroken() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    // macOS ships /bin/bash, /usr/sbin/sshd and /usr/bin/ssh, so the paths
    // below say nothing about a Mac. It is reported as iosAppOnMac instead.
    if isiOSAppOnMac() {
      return false
    }

    let jailbreakPaths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/",
      "/usr/bin/ssh",
      "/var/jb",
      "/Applications/Sileo.app",
      "/var/binpack",
    ]
    if jailbreakPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
      return true
    }

    // The sandbox forbids writing outside the app container; a write that
    // succeeds means the sandbox is gone.
    let probe = "/private/\(UUID().uuidString)"
    do {
      try "gt_device_integrity".write(toFile: probe, atomically: true, encoding: .utf8)
      try? FileManager.default.removeItem(atPath: probe)
      return true
    } catch {
      return false
    }
    #endif
  }
}
