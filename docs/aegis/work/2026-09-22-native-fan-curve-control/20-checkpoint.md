# Workstream checkpoint

## Current state

- Current todo: none; implementation and bounded verification are complete.
- Active slice: native Kit contract, profile store/controller, compact popup
  controls, lifecycle wiring, and final command-line/live startup verification.
- Completed: approved design; plan and baseline saved; branch/worktree snapshot
  captured; Kit curve model and JSON smoke test pass; Kit/Sensors command-line
  typecheck passes; temporary app launched without the AppKit constraint crash;
  final diff committed as `012f2256`.
- Blockers: none known.
- Next step: preserve this evidence with the branch and update the existing PR
  only when its remote is explicitly available.

## Baseline and drift

Baseline refs are listed in `10-intent.md` and the parent plan. Compatibility
boundary remains unchanged: existing `fan_<id>_*` Store keys and manual/lifecycle
paths are retained. Drift decision: `continue`; falsifier is a requirement for
a second SMC owner, a new external service dependency, or an unsafe restoration
path. The first live run exposed and fixed a pre-hierarchy Auto Layout
constraint; the rerun stayed alive with no matching exception in the runtime log.
