## Unreleased

* iOS: an iPhone app on a Mac is no longer reported as jailbroken. The jailbreak checks are skipped there, and the new `iosAppOnMac` reading says it is a Mac.
* Android: `cloneEnvironment` no longer counts a cloning app being installed, only this app running inside one. The seven cloning-app `<queries>` entries are removed; Magisk's stays.

## 0.0.1

* Root, jailbreak, clone, emulator, developer-mode, installer and signature readings, ported from NewMobileChannel.
