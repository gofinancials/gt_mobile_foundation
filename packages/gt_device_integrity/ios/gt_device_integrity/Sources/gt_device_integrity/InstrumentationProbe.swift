import Darwin
import Foundation
import MachO

/// What `InstrumentationProbe` found. Each evidence entry says what raised its
/// reading.
struct InstrumentationReadings {
  let frida: Bool
  let hookingFramework: Bool
  let debuggerAttached: Bool
  let evidence: [String]
}

/// Looks for Frida, hooking libraries and an attached debugger from inside the
/// process. Like every in-process check it can itself be hooked; it raises the
/// cost of an attack rather than ruling one out.
///
/// Opens a socket to 127.0.0.1, so it should not run on the main thread.
final class InstrumentationProbe {
  /// frida-server's default port, and Frida Gadget's in its default listen
  /// mode.
  private static let fridaPort: UInt16 = 27042
  private static let fridaLibraries = ["frida", "gum-js"]
  private static let hookingLibraries = [
    "mobilesubstrate",
    "substrateloader",
    "substrateinserter",
    "libsubstrate",
    "libhooker",
    "substitute",
    "ellekit",
    "tweakinject",
  ]

  func read() -> InstrumentationReadings {
    let images = loadedImages()
    let fridaEvidence = imageEvidence(images, markers: Self.fridaLibraries) + portEvidence()
    let hookingEvidence = imageEvidence(images, markers: Self.hookingLibraries) + insertedLibrariesEvidence()
    let debuggerEvidence = isTraced() ? ["debugger:p_traced"] : []
    let evidence = fridaEvidence + hookingEvidence + debuggerEvidence

    return InstrumentationReadings(
      frida: !fridaEvidence.isEmpty,
      hookingFramework: !hookingEvidence.isEmpty,
      debuggerAttached: !debuggerEvidence.isEmpty,
      evidence: evidence
    )
  }

  private func loadedImages() -> [String] {
    let count = _dyld_image_count()

    return (0..<count).compactMap { index in
      guard let name = _dyld_get_image_name(index) else { return nil }

      return String(cString: name).lowercased()
    }
  }

  private func imageEvidence(_ images: [String], markers: [String]) -> [String] {
    let found = markers.filter { marker in images.contains { $0.contains(marker) } }

    return found.map { "image:\($0)" }
  }

  /// Xcode sets this for its own diagnostic libraries when it runs a debug
  /// build, which is why the verdict ignores instrumentation in debug builds.
  private func insertedLibrariesEvidence() -> [String] {
    let value = ProcessInfo.processInfo.environment["DYLD_INSERT_LIBRARIES"] ?? ""

    guard !value.isEmpty else { return [] }

    return ["env:DYLD_INSERT_LIBRARIES"]
  }

  private func portEvidence() -> [String] {
    guard isListening(port: Self.fridaPort) else { return [] }

    return ["port:\(Self.fridaPort)"]
  }

  /// A connect to the loopback address answers at once either way, and does
  /// not raise the local network permission prompt.
  private func isListening(port: UInt16) -> Bool {
    let descriptor = socket(AF_INET, SOCK_STREAM, 0)

    guard descriptor >= 0 else { return false }

    defer { close(descriptor) }

    let length = socklen_t(MemoryLayout<sockaddr_in>.size)
    var address = sockaddr_in()
    address.sin_len = UInt8(length)
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = port.bigEndian
    address.sin_addr.s_addr = inet_addr("127.0.0.1")

    let status = withUnsafePointer(to: &address) { pointer in
      pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(descriptor, $0, length) }
    }

    return status == 0
  }

  private func isTraced() -> Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    let status = sysctl(&name, UInt32(name.count), &info, &size, nil, 0)

    guard status == 0 else { return false }

    return (info.kp_proc.p_flag & P_TRACED) != 0
  }
}
