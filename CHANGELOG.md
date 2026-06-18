# Changelog

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
