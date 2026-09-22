# Workstream intent

- Requested outcome: expose ThermalForge-like fan profiles and curve control as
  native Stats functionality while preserving existing manual controls.
- Parent plan: `docs/aegis/plans/2026-09-22-native-fan-curve-control.md`.
- Scope: Kit curve contract/evaluator, Sensors persistence/controller, compact
  popup controls, lifecycle wiring, focused verification.
- Non-goals: no dependency on `127.0.0.1:60371`, no Xcode requirement, no
  replacement of the existing manual FanView path, no release/tap changes.
- Branch/HEAD at start: `codex/combined-popup-detail` /
  `3339829e59b8c6fead2d9829dcd519aaec437f76`.
- Success evidence: evaluator tests or command-line checks, Swift parse/manual
  build, visible native controls exercised one by one, automatic restoration,
  and no unrelated files committed.
- Stop states: `done`, `blocked`, `needs-verification`, `scope-exceeded`.
