# CONTROL

CONTROL is an iOS 14+ Objective-C/C app skeleton for TrollStore installation. It targets high-privilege device diagnostics and conservative configuration on A11+ devices.

Implemented modules:

- Battery reader through `AppleSmartBattery` / `IOPMPowerSource` IORegistry properties.
- Charging limit preference writer using Apple's low power / smart charging preference keys.
- Display module that reads panel identity through `IOMobileFramebuffer` and stores a preferred max FPS cap.
- CPU module that reads available sysctl frequency fields and reports why real max-frequency enforcement needs a device-specific kernel/PMGR backend.
- `control-helper`, a C command-line helper intended to run inside the app bundle with the same TrollStore entitlements.
- `CTRootRunHelper`, a persona-based spawn wrapper for running that helper as UID 0 on supported TrollStore setups.

Build on macOS with Xcode command line tools and `ldid`:

```sh
make clean package
```

The output is `CONTROL.tipa`. Install it with TrollStore.

Important device notes:

- TrollStore is not a kernel exploit. Direct CPU max-frequency control is not implemented because iOS does not expose a stable userspace write API for PMGR scheduler limits.
- Hard charge inhibition should be added only after verifying the target device's SMC keys. Battman documents useful keys such as `CH0C`, `CH0I`, `CH0R`, but blindly writing them can break charging behavior.
- Refresh-rate enforcement varies by display stack and device. This project stores the desired cap and exposes the place where a validated IOMobileFramebuffer/CoreDisplay backend should be added.
