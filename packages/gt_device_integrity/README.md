# gt_device_integrity

Reads what an Android or iOS device says about its own integrity, and returns
the readings. It does not decide anything: `gt_mobile_foundation` judges which
readings block the app.

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
