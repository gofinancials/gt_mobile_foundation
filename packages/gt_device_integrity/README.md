# gt_device_integrity

Reads what an Android or iOS device says about its own integrity, and returns
the readings. It does not decide anything: `gt_mobile_foundation` judges which
readings block the app.

It also produces attestation tokens (Play Integrity on Android, App Attest on
iOS) for an app to send to its backend. Every reading is taken inside the
app's process and can be hooked; a token checked by a server is what makes the
result hold.

```dart
final report = await const GtDeviceIntegrity().report();
```

| Reading | Android | iOS |
|---|---|---|
| `rooted` | su binaries (fixed paths and `PATH`), Magisk, test-keys | jailbreak files, or a write outside the sandbox; always false on a Mac |
| `emulator` | build fingerprint, model, hardware and product | the simulator |
| `cloneEnvironment` | parallel-space sandbox path, nested sandbox, renamed process | not measured (null) |
| `processNameMismatch`, `testKeys` | also counted above; reported alone for diagnostics | not measured |
| `developerMode` | Developer options on | not measured |
| `installer` | installing package, null when Android does not say | not measured |
| `signature` | SHA-256 of the first signing certificate | not measured |
| `iosAppOnMac` | not measured (null) | an iPhone app running on an Apple Silicon Mac |
| `frida` | `frida` or `gum-js-loop` in `/proc/self/maps`, Frida thread names, a listener on 127.0.0.1:27042 | a Frida library among the loaded images, the same listener |
| `hookingFramework` | Xposed, EdXposed, LSPosed, LSPatch or Substrate in maps; Xposed classes on the stack or loadable | Substrate, libhooker, Substitute, ElleKit or TweakInject loaded; `DYLD_INSERT_LIBRARIES` set |
| `debuggerAttached` | `Debug.isDebuggerConnected()` or a non-zero `TracerPid` | the process is `P_TRACED` |
| `instrumentationEvidence` | what raised the three readings above, e.g. `maps:frida`, `port:27042` | the same |

Android also counts a Magisk mount in `/proc/self/mounts` as `rooted`, since
Magisk hides its app under a random package name.

Port 27042 is the default for `frida-server` and for Frida Gadget in listen
mode. A server on another port, or a gadget in script mode, opens nothing
there, so the in-process checks matter more. Android Studio and Xcode attach a
debugger, and Xcode sets `DYLD_INSERT_LIBRARIES`, so foundation ignores these
three readings in debug builds.

`report()` runs on a background thread on both platforms, because the port
probe opens a socket. It throws `FormatException` when the answer names no
platform, so an emptied answer is not read as a clean device.

The checks come from NewMobileChannel's security channel, with three
differences:

- NMC folds root into its clone result; this package reports the two
  separately.
- NMC counts a cloning app being installed as a clone environment. This
  package does not: an installed cloning app does not mean this app is running
  inside it, and customers who use one for a second WhatsApp account were
  blocked.
- NMC's jailbreak paths include `/bin/bash` and `/usr/sbin/sshd`, which every
  Mac has, so an iPhone app on a Mac read as jailbroken. This package skips the
  jailbreak checks on a Mac and reports `iosAppOnMac` instead.

`report()` throws `MissingPluginException` on other platforms and
`PlatformException` if the platform fails. The caller decides whether to fail
open.

## Attestation

```dart
const plugin = GtDeviceIntegrity();
await plugin.prepareAttestation(cloudProjectNumber: 123456789); // app start
final once = await plugin.attest(challenge: serverChallenge); // login
final perRequest = await plugin.attestationToken(data: canonicalBody);
```

Each call returns a `GtAttestationToken`, a `GtAttestationUnavailable` (the
device cannot attest, e.g. no Google Play) or a `GtAttestationFailed` (this
attempt failed), with a snake_case `reason` and the platform's error `code`.
Send the problems to the backend too, so it can tell a failed attempt from an
app that skipped the call.

| | `attest(challenge)`: one-off | `attestationToken(data)`: per request |
|---|---|---|
| Android | classic Play Integrity request; nonce = base64url (padded) of SHA-256(challenge) | standard request; request hash = base64url (padded) of SHA-256(data); needs the project number |
| iOS | new App Attest key, attested with SHA-256(challenge); key ID kept in the Keychain (this device only) and returned as `keyId` | assertion with that key over SHA-256(data); `attestation_required` until `attest` has succeeded |

The server reproduces the SHA-256 to check the binding, and verifies the token
with Google's `decodeIntegrityToken` or Apple's App Attest checks. On iOS a
`key_invalidated` problem (after a reinstall or restore) deletes the stored key;
call `attest` again.

App setup:

- **Play Integrity:** link the Google Cloud project in Play Console and pass its
  number. Classic requests are rate-limited, so keep `attest` to registration or
  login.
- **App Attest:** add the App Attest capability, with
  `com.apple.developer.devicecheck.appattest-environment` set to `production`
  for release builds. The simulator answers `not_supported`. Apple rate-limits
  attestation, so roll it out gradually.

## Android

The plugin's manifest names Magisk under `<queries>`, which merges into the
host app. Without it Android 11 and later hide the package and the probe always
answers no.

## Trying the native checks

The unit tests mock the channel. To run the Kotlin and Swift on a device or
emulator:

```
cd example && flutter test integration_test
```
