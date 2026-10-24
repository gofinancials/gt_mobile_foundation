import Flutter
import UIKit

/// Reads what the device says about itself. Every entry is a measurement;
/// deciding which ones block the app belongs to gt_mobile_foundation.
///
/// The checks are NewMobileChannel's AppDelegate security channel. iOS cannot
/// read developer mode, the installer, the signature or a clone environment,
/// so those entries are absent rather than guessed.
public class GtDeviceIntegrityPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gt_device_integrity", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(GtDeviceIntegrityPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "report":
      result(report())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func report() -> [String: Any] {
    return [
      "platform": "ios",
      "packageName": Bundle.main.bundleIdentifier ?? "",
      "rooted": isJailbroken(),
      "emulator": isSimulator(),
    ]
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
