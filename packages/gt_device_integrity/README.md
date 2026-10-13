# gt_device_integrity

Reads what an Android or iOS device says about its own integrity, and returns
the readings. It does not decide anything: `gt_mobile_foundation` judges which
readings block the app.

```dart
final report = await const GtDeviceIntegrity().report();
```

| Reading | Android | iOS |
|---|---|---|
| `rooted` | su binaries (fixed paths and `PATH`), Magisk, test-keys | jailbreak files, or a write outside the sandbox |
| `emulator` | build fingerprint, model, hardware and product | the simulator |
| `cloneEnvironment` | parallel-space sandbox path, renamed process, a cloning app installed | not measured (null) |
| `processNameMismatch`, `testKeys` | also counted above; reported alone for diagnostics | not measured |
| `developerMode` | Developer options on | not measured |
| `installer` | installing package, null when Android does not say | not measured |
| `signature` | SHA-256 of the first signing certificate | not measured |

The checks come from NewMobileChannel's security channel. NMC folds root into
its clone result; this package reports the two separately.

`report()` throws `MissingPluginException` on other platforms and
`PlatformException` if the platform fails. The caller decides whether to fail
open.

## Android

The plugin's manifest names Magisk and seven cloning apps under `<queries>`,
which merge into the host app. Without them Android 11 and later hide those
packages and the probes always answer no.

## Trying the native checks

The unit tests mock the channel. To run the Kotlin and Swift on a device or
emulator:

```
cd example && flutter test integration_test
```
