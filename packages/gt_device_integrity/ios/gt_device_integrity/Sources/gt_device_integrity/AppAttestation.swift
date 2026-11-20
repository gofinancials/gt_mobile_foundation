import CryptoKit
import DeviceCheck
import Flutter
import Foundation
import Security

/// Produces App Attest attestations and assertions. Every answer is a
/// dictionary with a `status` of `ready`, `token`, `unavailable` or `failed`;
/// verifying a token is the backend's job.
///
/// `attest` generates a new key, attests it against SHA-256 of the server's
/// challenge, and keeps the key ID in the Keychain (this device only) once
/// Apple accepts it. `attestationToken` signs SHA-256 of the request data with
/// that key. The host app needs the App Attest capability; the simulator does
/// not support App Attest.
final class AppAttestation {
  private let service = DCAppAttestService.shared
  private let keyStore = AttestationKeyStore()

  func prepare(result: @escaping FlutterResult) {
    guard service.isSupported else { return result(problem("unavailable", "not_supported")) }

    result(["status": "ready"])
  }

  func attest(challenge: String?, result: @escaping FlutterResult) {
    guard let challenge else { return result(problem("failed", "invalid_arguments")) }
    guard service.isSupported else { return result(problem("unavailable", "not_supported")) }

    let clientDataHash = sha256(challenge)

    service.generateKey { keyId, error in
      guard let keyId else { return self.finish(result, self.problem(for: error)) }

      self.service.attestKey(keyId, clientDataHash: clientDataHash) { attestation, error in
        guard let attestation else { return self.finish(result, self.problem(for: error)) }

        self.keyStore.save(keyId)
        self.finish(result, self.token(attestation, keyId: keyId))
      }
    }
  }

  func token(data: String?, result: @escaping FlutterResult) {
    guard let data else { return result(problem("failed", "invalid_arguments")) }
    guard service.isSupported else { return result(problem("unavailable", "not_supported")) }
    guard let keyId = keyStore.load() else { return result(problem("failed", "attestation_required")) }

    let clientDataHash = sha256(data)

    service.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
      guard let assertion else { return self.finish(result, self.assertionProblem(for: error)) }

      self.finish(result, self.token(assertion, keyId: keyId))
    }
  }

  /// A key Apple no longer accepts (after a reinstall or a restore) is
  /// deleted, so the next `attest` starts clean.
  private func assertionProblem(for error: Error?) -> [String: Any] {
    let isInvalidKey = (error as? DCError)?.code == .invalidKey

    if isInvalidKey { keyStore.delete() }

    return problem(for: error)
  }

  private func problem(for error: Error?) -> [String: Any] {
    let code = (error as? DCError)?.code

    switch code {
    case .featureUnsupported:
      return problem("unavailable", "not_supported", code: code?.rawValue)
    case .invalidKey:
      return problem("failed", "key_invalidated", code: code?.rawValue)
    case .serverUnavailable:
      return problem("failed", "server_unavailable", code: code?.rawValue)
    default:
      return problem("failed", "app_attest_error", code: code?.rawValue)
    }
  }

  private func problem(_ status: String, _ reason: String, code: Int? = nil) -> [String: Any] {
    var answer: [String: Any] = ["status": status, "reason": reason]
    answer["code"] = code

    return answer
  }

  private func token(_ data: Data, keyId: String) -> [String: Any] {
    return ["status": "token", "platform": "ios", "token": data.base64EncodedString(), "keyId": keyId]
  }

  private func sha256(_ value: String) -> Data {
    let digest = SHA256.hash(data: Data(value.utf8))

    return Data(digest)
  }

  /// DeviceCheck calls back on its own queue; Flutter answers on the main one.
  private func finish(_ result: @escaping FlutterResult, _ answer: [String: Any]) {
    DispatchQueue.main.async { result(answer) }
  }
}

/// Keeps the attested App Attest key ID. Stored this-device-only, so a backup
/// restored to another phone does not bring back a key that phone cannot use.
private struct AttestationKeyStore {
  private let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "ng.gofinancials.gt_device_integrity.app_attest",
    kSecAttrAccount as String: "key_id",
  ]

  func load() -> String? {
    var lookup = query
    lookup[kSecReturnData as String] = true
    lookup[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(lookup as CFDictionary, &item)

    guard status == errSecSuccess, let data = item as? Data else { return nil }

    return String(data: data, encoding: .utf8)
  }

  func save(_ keyId: String) {
    delete()

    var item = query
    item[kSecValueData as String] = Data(keyId.utf8)
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    SecItemAdd(item as CFDictionary, nil)
  }

  func delete() {
    SecItemDelete(query as CFDictionary)
  }
}
