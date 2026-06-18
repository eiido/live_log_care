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
// debug-only by default; opt into redacted release logging:
// RedactingDioInterceptor(logInRelease: true)
```

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
    // printer: MyPrinter(),
    // redactionEnabled: true,    // (default) never turn this off in production
  ),
);

// Teach the redactor about your domain's secrets:
LogRedactor.addSensitiveKeys(['iban', 'card_holder']);
LogRedactor.addValuePatterns([RegExp(r'\b\d{16}\b')]); // bare 16-digit numbers
LogRedactor.mask = '[hidden]';
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

## License

MIT
