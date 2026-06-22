# live_log_care

**Redaction-safe logging for Flutter.** A drop-in logging facade that is build-mode
gated (silent in release) and **automatically scrubs secrets and PII** —
passwords, tokens, cookies, OTPs, national IDs, bearer/JWT tokens, card numbers —
from your log messages, your Dio traffic and your Bloc state, *before anything is
written*.

Most apps leak credentials to device logs without realizing it: a `PrettyDioLogger`
left on in release, a cookie printed by an auth interceptor, a Bloc state containing
a password. `live_log_care` makes the safe path the default one.

## Features

- 🔒 **Automatic redaction** — secrets are masked everywhere, including nested maps,
  lists, headers and request/response bodies.
- 🌗 **True build-mode gating** — uses `ProductionFilter`, so in release only
  `warning`/`error` are emitted (not the `logger` default, which silently drops
  *all* release logs).
- 🛰️ **Redaction-safe Dio interceptor** — replaces `PrettyDioLogger`; debug-only by
  default.
- 🧊 **Bloc observer** — routes Bloc/Cubit lifecycle + errors through the same gate.
- 🪝 **Pluggable crash reporting** — forward release errors to Crashlytics/Sentry via
  a tiny interface; the package itself pulls in neither.
- ⚙️ **Configurable** — add your own sensitive keys/patterns, change the mask, set
  per-build levels, swap the printer.

## Install

```sh
flutter pub add live_log_care
```

## Usage

```dart
import 'package:live_log_care/live_log_care.dart';

// Log — use instead of print() / debugPrint().
LiveLog.t('verbose trace');
LiveLog.d('dev-only diagnostic');
LiveLog.i('user opened loan #$id');
LiveLog.w('retrying request');
LiveLog.e('payment failed', error: e, stackTrace: s);

// Secrets are masked automatically:
LiveLog.d({'login': 'a@b.com', 'password': 'hunter2'});
// → {login: a@b.com, password: ***REDACTED***}
```

### Dio

```dart
final dio = Dio()..interceptors.add(RedactingDioInterceptor());
// Bodies/headers render as indented JSON by default — split across lines, so the
// console can't truncate one long line. For compact Map.toString():
// RedactingDioInterceptor(prettyJson: false)
// debug-only by default; opt into redacted release logging:
// RedactingDioInterceptor(logInRelease: true)
```

### Clean, copy-friendly output

By default logs use `logger`'s boxed `PrettyPrinter`, and on Android each line is
tagged with the `I/flutter (PID):` prefix that the OS log layer adds. For output
that reads as real JSON and copies cleanly — no box, and no prefix in the
**VS Code Debug Console** — opt into the `clean()` preset:

```dart
LiveLog.configure(LiveLogConfig.clean());
final dio = Dio()..interceptors.add(RedactingDioInterceptor());

LiveLog.d({'id': 6, 'name': 'Test Qard', 'national_id': '123'});
// [D] {
//   "id": 6,
//   "name": "Test Qard",
//   "national_id": "***REDACTED***"
// }
```

`clean()` swaps in `CleanPrinter` (no border, no ANSI colors) and `DevLogOutput`
(routes through `dart:developer.log`, so the Debug Console shows each entry as a
single, prefix-free, copyable block). Redaction still runs first. All other
secure defaults apply; override them via `clean()`'s parameters, or wire
`CleanPrinter`/`DevLogOutput` into `LiveLogConfig` yourself.

### Bloc

```dart
Bloc.observer = LiveLogBlocObserver();
```

### Crash reporting (optional)

```dart
class CrashlyticsSink implements CrashSink {
  @override
  void recordError(Object error, StackTrace? st, Object? context) =>
      FirebaseCrashlytics.instance.recordError(error, st, reason: context);
}

LiveLog.crashSink = CrashlyticsSink(); // only release `error`s are forwarded
```

## Configuration

Everything has a secure default; configure only what you need, once at startup:

```dart
LiveLog.configure(
  const LiveLogConfig(
    releaseLevel: LogLevel.error, // even quieter in release
    // enabled: false,            // kill switch
    // printer: CleanPrinter(),   // or BoxedPrinter() (default), or your own
    // output: DevLogOutput(),    // or ConsoleOutput() (default), MultiOutput, FileOutput
    // filter: MyFilter(),        // custom gating; default is a ThresholdFilter
    // redactionEnabled: true,    // (default) never turn this off in production
    // revealSecretsInDebug: false,// redact in debug too (defaults to kDebugMode; release always redacted)
  ),
);

// Teach the redactor about your domain's secrets:
LogRedactor.addSensitiveKeys(['iban', 'card_holder']);
LogRedactor.addValuePatterns([RegExp(r'\b\d{16}\b')]); // bare 16-digit numbers
LogRedactor.mask = '[hidden]';
```

The logging engine is self-contained — no third-party `logger` dependency.
Compose your own pipeline from the bundled building blocks, or implement
`LogPrinter` / `LogOutput` / `LogFilter` yourself:

```dart
// Console + a rotating file, both fed the same redacted, gated stream:
LiveLog.configure(
  LiveLogConfig(
    output: MultiOutput([const ConsoleOutput(), FileOutput('app.log')]),
  ),
);
```

## What gets redacted by default

Keys (case-insensitive, substring): `password`, `passwd`, `pwd`, `token`,
`access_token`, `refresh_token`, `id_token`, `auth_token`, `authorization`,
`bearer`, `cookie`, `set-cookie`, `session_id`, `api_session`, `national_id`,
`ssn`, `otp`, `secret`, `client_secret`, `api_key`, `x-api-key`, `private_key`,
`credit_card`, `card_number`, `cvv`, `cvc`.

Values: `Bearer <token>` and JWTs anywhere in a string. Add your own with
`addValuePatterns`.

> Redaction reduces risk; it is not a guarantee for arbitrarily-shaped data. Keep
> debug network logging out of release for anything highly sensitive (the default).

Real secret values are shown while debugging locally **by default** —
`revealSecretsInDebug` defaults to `kDebugMode`, so values are un-masked **in
debug builds only**; release builds are always redacted regardless, so there's
no production-leak risk. To redact in debug too — recommended if your debug logs
may be screenshotted, screen-shared, or captured in CI — set
`revealSecretsInDebug: false`.

## License

MIT
