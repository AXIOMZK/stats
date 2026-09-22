# Native fan control baseline — 2026-09-22

## Observed source owners

- `Modules/Sensors/popup.swift`: the native Sensors popup and existing `FanView` manual controls.
- `Modules/Sensors/main.swift`: `Sensors` lifecycle, usage callback, sleep/wake and termination restoration.
- `Modules/Sensors/values.swift`: `Fan` value model and persisted `customSpeed`/`customMode` state.
- `Modules/Sensors/readers.swift`: SMC fan and temperature sampling.
- `Kit/helpers.swift`: `SMCHelper` fan mode/speed/reset and helper permission surface.
- `Kit/types.swift`: shared notifications and fan value types.
- `Kit/plugins/Store.swift`: existing typed key/value persistence.
- `Tests/Kit.swift`: command-line-testable Kit target and current popup hover regression coverage.

## Existing behavior to preserve

Existing per-fan sliders, automatic/forced/off/turbo mode buttons, synchronized
fan control, helper approval, and sleep/termination restoration remain the
direct manual-control path. The new profile path is additive and can be
disabled without changing that behavior.

## ThermalForge observations (external reference only)

The local service at `127.0.0.1:60371` exposes profile concepts (stop/start
temperatures, ceiling, maximum speed, ramping, sustained trigger, curve shape,
and per-fan status). It is not a runtime dependency or source of truth for the
Stats implementation. The native implementation must work when the service is
absent.

## Toolchain boundary

The user does not want Xcode installed. Verification therefore uses
`swiftc -parse`, command-line Swift compilation where possible, focused Kit
tests when the available toolchain permits, and manual runtime inspection of
the installed app. `xcodebuild`/full XCTest execution is not an acceptance
requirement when unavailable from Command Line Tools alone.
