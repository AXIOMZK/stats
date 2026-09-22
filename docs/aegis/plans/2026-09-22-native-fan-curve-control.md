# Native fan curve control

## Aegis Visibility

This plan is useful because the feature introduces a persisted profile contract,
a new controller owner, and shared fan-control behavior across Kit, Sensors,
the popup UI, lifecycle restoration, and command-line verification.

## Goal and approved scope

Add a native Stats fan-profile/curve control surface that provides the useful
control strategy exposed by the local ThermalForge page while retaining the
existing Stats fan controls. A user can select or edit a profile, apply it to
the detected fans, see temperature-driven targets, and restore Apple automatic
control. The implementation is native to Stats and must not call or require
`http://127.0.0.1:60371/`.

Acceptance evidence:

1. Existing per-fan manual controls still operate unchanged.
2. Built-in Silent, Balanced, Performance, Max, and Smart profiles can be
   selected, applied, and restored safely.
3. Custom profiles persist through relaunch and support curve points, stop/start
   and ceiling temperatures, maximum speed, ramp up/down, sustained trigger,
   curve shape, and per-fan override data.
4. Manual fan selection has priority over automatic curve evaluation; sleep and
   termination restore safe automatic control.
5. The compact profile row is collapsed by default so the Sensors popup remains
   usable.

## Architecture

- `Kit`: owns pure, Codable `FanCurveProfile`/point/parameter types and a
  deterministic temperature-to-speed evaluator. This is the testable contract.
- `Sensors`: owns profile persistence and the active `FanCurveController`, which
  consumes sampled CPU/GPU temperatures, maps percentages to each fan's min/max
  RPM, applies smoothing/sustained-trigger rules, and coordinates lifecycle
  restoration through `SMCHelper`.
- `FanView` remains the existing direct manual owner. The controller observes
  the same fan state and treats an explicit manual mode/slider as higher
  priority; it does not fork or replace the manual UI path.
- `Popup`: adds a compact profile selector, Apply, Restore Automatic, and an
  expand/collapse editor. It uses the Sensors owner through notifications or
  narrow callbacks rather than owning SMC writes.
- `Store`: persists versioned JSON for profiles and the active profile id.

## Tech stack and baseline/authority references

Swift/AppKit, existing Stats Store and SMC helper. Baseline: [2026-09-22
native fan control](../baselines/2026-09-22-native-fan-control.md). Source
owners are `Modules/Sensors/{main,popup,values,readers}.swift`,
`Kit/{types.swift,helpers.swift,plugins/Store.swift}`, and `Tests/Kit.swift`.
The approved native design in the user conversation is the authority for scope;
the local ThermalForge endpoint is an observation and compatibility reference,
not an authority.

## Compatibility boundary

No existing Store keys are renamed or repurposed. Existing `fan_<id>_speed`,
`fan_<id>_mode`, helper approval, mode buttons, sync notifications, and restore
paths continue to work. If profile controls are disabled or no profile is
active, behavior is exactly the existing manual/automatic behavior. Profile
state is versioned and may be ignored safely if unreadable.

## Change Necessity

- User-visible need: control ThermalForge-like fan strategies directly from the
  native Stats Sensors window.
- Non-code option: keep opening the local web service, which violates the
  requested native feature and leaves behavior dependent on another daemon.
- Why code is necessary: only Stats code can provide native persistence, curve
  evaluation, SMC lifecycle safety, and UI integration without that service.
- Minimum boundary: shared Kit model/evaluator, Sensors profile owner/controller,
  compact popup controls, and focused tests; retain all existing manual code.
- Decision: `code-change`.

## Ripple Signal Triage and integrity

Persistence, producer/consumer, lifecycle, shared SMC contract, and UI signals
fire. The canonical source of truth is the versioned profile data plus the
active profile id in Stats Store; the active controller is the only automatic
curve writer. Temperature samples come from `SensorsReader`; fan limits and
manual state come from `Fan`. No second web owner or fallback service is added.

## TDD Route

Mode: `auto`. Decision: `strict`. Authority: Aegis auto rule for behavior,
shared/core contract, persistence, permission, and regression signals. Test
posture: write focused Kit evaluator/serialization tests before implementation,
then add lifecycle/manual-priority checks where they can run without hardware.
Verification also includes command-line parse/compile and reversible live UI
inspection because SMC hardware behavior cannot be fully represented by unit
tests.

## Ordered implementation tasks

1. Extend `Kit/types.swift` with Codable profile/point/parameter/shape types and
   a pure clamped, piecewise evaluator with built-in profiles. Add focused tests
   to `Tests/Kit.swift` for boundaries, interpolation, caps, monotonic shapes,
   and JSON round trips.
2. Add a versioned profile store and active-profile controller under the existing
   Sensors owners. Seed built-ins, preserve custom profiles, compute the highest
   relevant CPU/GPU temperature, map percentages to each fan's min/max RPM,
   respect manual priority, smooth changes, and restore automatic control on
   sleep/termination.
3. Add the compact collapsed-by-default profile row and editor to
   `Modules/Sensors/popup.swift`; wire Apply, Restore Automatic, profile CRUD,
   and per-fan override controls through the Sensors owner without direct UI
   SMC writes.
4. Wire usage callbacks, notifications, lifecycle, and popup refreshes; ensure
   helper permission failures remain visible through the existing path.
5. Verify with diff checks, Swift parsing/manual compilation, focused tests when
   available, and the running app: exercise every new control, confirm visible
   targets/mode changes, restore automatic, inspect frontend/runtime logs, and
   leave the repository free of generated artifacts.

## Verification and residual risk

Required commands include `git diff --check`, `swiftc -parse` for every changed
Swift source, and a command-line Kit/Sensors build using the installed Swift
toolchain. Full `xcodebuild`/XCTest is explicitly unavailable without Xcode and
is not claimed. Live verification must be conservative: avoid sustained manual
fan writes, restore automatic after each control check, and record helper or
hardware permission limitations.

Residual risks are SMC hardware differences, helper authorization, sensor naming
variation, and races between an explicit manual slider and a curve tick. The
controller must fail closed to automatic/reset when it cannot read a valid
temperature or fan limit. A future retirement point is only justified if Stats
adopts a different first-party fan-profile owner; no existing manual path is
retired in this change.
