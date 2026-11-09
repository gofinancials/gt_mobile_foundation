## Unreleased

* Attestation: `prepareAttestation`, `attest` and `attestationToken` produce Play Integrity tokens on Android (classic and standard requests) and App Attest attestations and assertions on iOS, returning a sealed `GtAttestationResult`. Android depends on `com.google.android.play:integrity`.
* New `frida`, `hookingFramework` and `debuggerAttached` readings, with `instrumentationEvidence` saying what raised them.
* Android: a Magisk mount in `/proc/self/mounts` counts as `rooted`.
* `report()` runs on a background thread on both platforms, and throws `FormatException` when the answer names no platform instead of reading it as a clean device.

* iOS: an iPhone app on a Mac is no longer reported as jailbroken. The jailbreak checks are skipped there, and the new `iosAppOnMac` reading says it is a Mac.
* Android: `cloneEnvironment` no longer counts a cloning app being installed, only this app running inside one. The seven cloning-app `<queries>` entries are removed; Magisk's stays.

## 0.0.1

* Root, jailbreak, clone, emulator, developer-mode, installer and signature readings, ported from NewMobileChannel.
