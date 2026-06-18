/// Redaction-safe logging for Flutter.
///
/// A single import gives you:
/// - [LiveLog] — a static, build-mode-gated logging facade.
/// - [LiveLogConfig] / [LogLevel] — optional startup configuration.
/// - [LogRedactor] — scrubs secrets/PII from anything before it is logged.
/// - [RedactingDioInterceptor] — a redaction-safe `Dio` logger.
/// - [LiveLogBlocObserver] — routes Bloc/Cubit events through [LiveLog].
/// - [CrashSink] — pluggable hook for release `error`s (Crashlytics/Sentry).
///
/// The logging engine is self-contained (no third-party logger dependency).
/// Customize it with bundled — or your own — building blocks:
/// - Printers: [BoxedPrinter] (default), [CleanPrinter].
/// - Outputs: [ConsoleOutput] (default), [DevLogOutput], [MultiOutput],
///   [FileOutput].
/// - Filters: [ThresholdFilter], or any [LogFilter].
library;

export 'src/core.dart'
    show
        LogLevel,
        LogEvent,
        OutputEvent,
        LogFilter,
        ThresholdFilter,
        LogPrinter,
        LogOutput;
export 'src/crash_sink.dart';
export 'src/file_output/file_output.dart';
export 'src/live_log.dart' show LiveLog, LiveLogConfig;
export 'src/live_log_bloc_observer.dart';
export 'src/log_redactor.dart' show LogRedactor;
export 'src/outputs.dart' show ConsoleOutput, DevLogOutput, MultiOutput;
export 'src/printers.dart' show BoxedPrinter, CleanPrinter;
export 'src/redacting_dio_interceptor.dart';
