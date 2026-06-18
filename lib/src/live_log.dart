import 'package:flutter/foundation.dart';

import 'core.dart';
import 'crash_sink.dart';
import 'log_redactor.dart';
import 'outputs.dart';
import 'printers.dart';

/// Immutable startup configuration for [LiveLog]. Pass to [LiveLog.configure].
///
/// Every field has a secure default, so configuring is optional.
@immutable
class LiveLogConfig {
  const LiveLogConfig({
    this.enabled = true,
    this.debugLevel = LogLevel.trace,
    this.releaseLevel = LogLevel.warning,
    this.filter,
    this.printer,
    this.output,
    this.crashSink,
    this.redactionEnabled = true,
    this.revealSecretsInDebug = false,
  });

  /// Preset for clean, copy-friendly output: `Map`/`Iterable` messages render
  /// as indented JSON with no boxed border, and — because output is routed
  /// through `dart:developer.log` ([DevLogOutput] + [CleanPrinter]) — no
  /// `I/flutter (PID):` prefix in the VS Code Debug Console.
  ///
  /// All other secure defaults still apply; override any via the parameters.
  /// Pass [RedactingDioInterceptor]`(prettyJson: true)` for matching network
  /// logs.
  factory LiveLogConfig.clean({
    bool enabled = true,
    LogLevel debugLevel = LogLevel.trace,
    LogLevel releaseLevel = LogLevel.warning,
    CrashSink? crashSink,
    bool redactionEnabled = true,
    bool revealSecretsInDebug = false,
  }) => LiveLogConfig(
    enabled: enabled,
    debugLevel: debugLevel,
    releaseLevel: releaseLevel,
    printer: const CleanPrinter(),
    output: const DevLogOutput(),
    crashSink: crashSink,
    redactionEnabled: redactionEnabled,
    revealSecretsInDebug: revealSecretsInDebug,
  );

  /// Master switch. When `false`, nothing is logged in any build.
  final bool enabled;

  /// Minimum level emitted in debug builds.
  final LogLevel debugLevel;

  /// Minimum level emitted in release builds. Defaults to [LogLevel.warning] so
  /// `trace`/`debug`/`info` are silenced in production.
  final LogLevel releaseLevel;

  /// Optional custom gate. When set, it fully controls emission and
  /// [enabled]/[debugLevel]/[releaseLevel] are ignored. Defaults to a
  /// build-mode-aware [ThresholdFilter].
  final LogFilter? filter;

  /// Optional custom printer. Defaults to [BoxedPrinter].
  final LogPrinter? printer;

  /// Optional custom output. Defaults to [ConsoleOutput].
  final LogOutput? output;

  /// Optional crash-reporting sink for release `error`s. See [CrashSink].
  final CrashSink? crashSink;

  /// Whether messages pass through [LogRedactor] before logging. Strongly
  /// recommended to leave enabled.
  final bool redactionEnabled;

  /// Reveal real secret values in **debug builds only**, to aid local
  /// debugging. Release builds are **always** redacted regardless — this flag
  /// has no effect when `kReleaseMode` is true.
  ///
  /// Defaults to `false`: the safe path stays the default. Turn it on only on
  /// your own machine; never rely on it for anything that ships.
  final bool revealSecretsInDebug;
}

/// Centralized, redaction-safe logging facade.
///
/// **Use these instead of `print` / `debugPrint`.** Every message is passed
/// through [LogRedactor] first, so credentials, tokens, cookies, OTPs and PII
/// can never reach the output.
///
/// Build-mode gating is enforced via a [ThresholdFilter] computed from the
/// configured levels, so in release builds only `warning` and `error` are
/// emitted by default (configure with [LiveLogConfig.releaseLevel]). Wire
/// [crashSink] to forward release `error`s to Crashlytics/Sentry.
///
/// ```dart
/// LiveLog.d('cheap dev-only diagnostic');
/// LiveLog.e('payment failed', error: e, stackTrace: s);
/// ```
abstract final class LiveLog {
  static LiveLogConfig _config = const LiveLogConfig();
  static LogFilter _filter = _buildFilter(_config);
  static LogPrinter _printer = _buildPrinter(_config);
  static LogOutput _output = _buildOutput(_config);

  /// Crash-reporting destination for release `error`s. Also settable via
  /// [LiveLogConfig.crashSink].
  static CrashSink? crashSink;

  static LogFilter _buildFilter(LiveLogConfig c) =>
      c.filter ??
      ThresholdFilter(
        !c.enabled
            ? LogLevel.off
            : (kReleaseMode ? c.releaseLevel : c.debugLevel),
      );

  static LogPrinter _buildPrinter(LiveLogConfig c) =>
      c.printer ?? const BoxedPrinter();

  static LogOutput _buildOutput(LiveLogConfig c) =>
      c.output ?? const ConsoleOutput();

  /// Apply [config]. Optional — secure defaults apply without calling this.
  static void configure(LiveLogConfig config) {
    _config = config;
    _filter = _buildFilter(config);
    _printer = _buildPrinter(config);
    _output = _buildOutput(config);
    if (config.crashSink != null) crashSink = config.crashSink;
  }

  /// Whether redaction is currently in effect for this build.
  ///
  /// `false` only when redaction is fully disabled
  /// ([LiveLogConfig.redactionEnabled] is `false`), or when
  /// [LiveLogConfig.revealSecretsInDebug] is set **and** this is a debug build.
  /// Always `true` in release unless redaction is fully disabled — so secrets
  /// can never be revealed in a release build via the debug-reveal flag.
  ///
  /// [RedactingDioInterceptor] reads this so the same rule applies to network
  /// logs.
  static bool get redactionActive {
    if (!_config.redactionEnabled) return false;
    if (kDebugMode && _config.revealSecretsInDebug) return false;
    return true;
  }

  static Object? _r(Object? message) =>
      redactionActive ? LogRedactor.redact(message) : message;

  static void _emit(
    LogLevel level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final event = LogEvent(
      level,
      message,
      error: error,
      stackTrace: stackTrace,
    );
    if (!_filter.shouldLog(event)) return;
    _output.output(OutputEvent(event, _printer.log(event)));
  }

  /// Trace — most verbose, dev only by default.
  static void t(Object? message) => _emit(LogLevel.trace, _r(message));

  /// Debug — dev only by default.
  static void d(Object? message) => _emit(LogLevel.debug, _r(message));

  /// Info — dev only by default.
  static void i(Object? message) => _emit(LogLevel.info, _r(message));

  /// Warning — emitted in all builds by default.
  static void w(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _emit(
        LogLevel.warning,
        _r(message),
        error: error,
        stackTrace: stackTrace,
      );

  /// Error — emitted in all builds; also forwarded to [crashSink] in release.
  static void e(Object? message, {Object? error, StackTrace? stackTrace}) {
    final redacted = _r(message);
    _emit(LogLevel.error, redacted, error: error, stackTrace: stackTrace);
    if (kReleaseMode && error != null) {
      crashSink?.recordError(error, stackTrace, redacted);
    }
  }
}
