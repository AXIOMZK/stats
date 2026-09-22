# Evidence bundle

- Status: `evidence-finalized` for the native fan-curve implementation slice.
- Static checks: `swiftc -parse` for Kit, Sensors, and Tests sources; `git diff
  --check`; all passed.
- Compile checks: full Kit Swift typecheck with the existing Objective-C
  bridging header and Helper protocol; Kit dynamic library build; Sensors
  dynamic library build with the Command Line Tools Swift compiler; all passed
  with only existing SDK deprecation warnings.
- Behavioral smoke: an isolated executable exercised stop/start boundaries,
  piecewise interpolation, max-speed cap, and Codable round trip; printed
  `fan-curve-smoke-ok`.
- Live startup: a temporary copied Stats.app with the rebuilt Kit and Sensors
  frameworks launched and remained running; a first-run Auto Layout exception
  was fixed, and the final launch produced no matching exception or immediate
  termination in the macOS unified log.
- Interactive scope: the temporary app's Sensors settings were opened and the
  popup configuration surface was inspected. Direct SMC writes were not forced
  during verification; helper and hardware control remain a bounded residual
  risk.
- Uncovered: full XCTest/xcodebuild is unavailable with Command Line Tools only;
  the global keyboard shortcut did not open the popup through CUA, so every
  profile button was not hardware-exercised in this run.
- Residual risk: actual SMC helper authorization, temperature sensor variation,
  and manual-versus-curve interaction on physical fan hardware.
