# Changelog

## 2.0.0

### Breaking

- Removed the `logger` dependency; the logging engine is now self-contained.
  `LogLevel` is now this package's own enum (member names unchanged, so
  `LogLevel.error` etc. keep working), and `LiveLogConfig.printer` / `.output`
  now take this package's `LogPrinter` / `LogOutput` types. Apps that passed a
  `logger`-based `PrettyPrinter` or custom printer/output must switch to the
  bundled ones (`BoxedPrinter`, `CleanPrinter`, `ConsoleOutput`, …).

### Added

- Self-contained logging core: `LogLevel`, `LogEvent`, `OutputEvent`,
  `LogPrinter`, `LogOutput`, `LogFilter`.
- Printers: `BoxedPrinter` (default — the familiar boxed, colored look) and
  `CleanPrinter` (borderless, prefix-free).
- Outputs: `ConsoleOutput` (default), `DevLogOutput` (`dart:developer.log`),
  `MultiOutput` (fan-out), and a WASM-safe `FileOutput`.
- Filters: pluggable `LogFilter` (`LiveLogConfig.filter`) with the default
  `ThresholdFilter`.
- `LiveLogConfig.clean()` preset: indented-JSON, no box, no `I/flutter (PID):`
  prefix in the VS Code Debug Console.
- `RedactingDioInterceptor(prettyJson: true)` renders request/response headers
  and bodies as indented JSON instead of `Map.toString()`.
- `LogRedactor.prettyJson` / `redactJson` helpers.

### Fixed

- WASM compatibility: dropping `logger` removes its `dart:io`-importing web
  stub; the package now compiles cleanly to WASM.
- Raised the `dio` lower bound to `>=5.2.0` (first version with `DioException`),
  fixing pub.dev downgrade analysis.

## 1.0.0

Initial release.

- `LiveLog` — static, redaction-safe logging facade (`t`/`d`/`i`/`w`/`e`).
- Build-mode gating via `ProductionFilter` + level: in release only `warning`
  and `error` are emitted by default.
- `LogRedactor` — scrubs passwords, tokens, cookies, OTPs, national IDs, auth
  headers, bearer/JWT tokens and card numbers from every message, header map and
  request/response body. Extend with `addSensitiveKeys`, `addValuePatterns` and a
  custom `mask`.
- `RedactingDioInterceptor` — redaction-safe Dio logger; debug-only by default,
  opt-in release logging via `logInRelease`.
- `LiveLogBlocObserver` — routes Bloc/Cubit lifecycle + errors through `LiveLog`.
- `CrashSink` — pluggable interface to forward release `error`s to
  Crashlytics/Sentry without depending on either.
- `LiveLogConfig` — optional startup configuration (enable/disable, debug/release
  levels, custom printer/output, crash sink, redaction toggle).
