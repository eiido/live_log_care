/// Redaction-safe logging for Flutter.
///
/// A single import gives you:
/// - [LiveLog] — a static, build-mode-gated logging facade.
/// - [LiveLogConfig] / [LogLevel] — optional startup configuration.
/// - [LogRedactor] — scrubs secrets/PII from anything before it is logged.
/// - [RedactingDioInterceptor] — a redaction-safe `Dio` logger.
/// - [LiveLogBlocObserver] — routes Bloc/Cubit events through [LiveLog].
/// - [CrashSink] — pluggable hook for release `error`s (Crashlytics/Sentry).
library;

export 'src/crash_sink.dart';
export 'src/live_log.dart' show LiveLog, LiveLogConfig, LogLevel;
export 'src/live_log_bloc_observer.dart';
export 'src/log_redactor.dart' show LogRedactor;
export 'src/redacting_dio_interceptor.dart';
