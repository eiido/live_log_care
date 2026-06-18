import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as pkg;

import 'crash_sink.dart';
import 'log_redactor.dart';

/// Severity levels, re-exported from `logger` so you can configure [LiveLog]
/// without importing `logger` directly.
typedef LogLevel = pkg.Level;

/// Immutable startup configuration for [LiveLog]. Pass to [LiveLog.configure].
///
/// Every field has a secure default, so configuring is optional.
@immutable
class LiveLogConfig {
  const LiveLogConfig({
    this.enabled = true,
    this.debugLevel = pkg.Level.trace,
    this.releaseLevel = pkg.Level.warning,
    this.printer,
    this.output,
    this.crashSink,
    this.redactionEnabled = true,
  });

  /// Master switch. When `false`, nothing is logged in any build.
  final bool enabled;

  /// Minimum level emitted in debug builds.
  final LogLevel debugLevel;

  /// Minimum level emitted in release builds. Defaults to [LogLevel.warning] so
  /// `trace`/`debug`/`info` are silenced in production.
  final LogLevel releaseLevel;

  /// Optional custom printer. Defaults to a clean [pkg.PrettyPrinter].
  final pkg.LogPrinter? printer;

  /// Optional custom output. Defaults to the console.
  final pkg.LogOutput? output;

  /// Optional crash-reporting sink for release `error`s. See [CrashSink].
  final CrashSink? crashSink;

  /// Whether messages pass through [LogRedactor] before logging. Strongly
  /// recommended to leave enabled.
  final bool redactionEnabled;
}

/// Centralized, redaction-safe logging facade.
///
/// **Use these instead of `print` / `debugPrint`.** Every message is passed
/// through [LogRedactor] first, so credentials, tokens, cookies, OTPs and PII
/// can never reach the output.
///
/// Build-mode gating is enforced via [pkg.ProductionFilter] + level, so in
/// release builds only `warning` and `error` are emitted by default (configure
/// with [LiveLogConfig.releaseLevel]). Wire [crashSink] to forward release
/// `error`s to Crashlytics/Sentry.
///
/// ```dart
/// LiveLog.d('cheap dev-only diagnostic');
/// LiveLog.e('payment failed', error: e, stackTrace: s);
/// ```
abstract final class LiveLog {
  static LiveLogConfig _config = const LiveLogConfig();
  static pkg.Logger _logger = _build(_config);

  /// Crash-reporting destination for release `error`s. Also settable via
  /// [LiveLogConfig.crashSink].
  static CrashSink? crashSink;

  static pkg.Logger _build(LiveLogConfig c) => pkg.Logger(
    // ProductionFilter honours [level] in every build — unlike the default
    // DevelopmentFilter, which silently drops all logs in release.
    filter: pkg.ProductionFilter(),
    level: !c.enabled
        ? pkg.Level.off
        : (kReleaseMode ? c.releaseLevel : c.debugLevel),
    printer: c.printer ??
        pkg.PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 8,
          colors: true,
          printEmojis: false,
        ),
    output: c.output,
  );

  /// Apply [config]. Optional — secure defaults apply without calling this.
  static void configure(LiveLogConfig config) {
    _config = config;
    _logger = _build(config);
    if (config.crashSink != null) crashSink = config.crashSink;
  }

  static Object? _r(Object? message) =>
      _config.redactionEnabled ? LogRedactor.redact(message) : message;

  /// Trace — most verbose, dev only by default.
  static void t(Object? message) => _logger.t(_r(message));

  /// Debug — dev only by default.
  static void d(Object? message) => _logger.d(_r(message));

  /// Info — dev only by default.
  static void i(Object? message) => _logger.i(_r(message));

  /// Warning — emitted in all builds by default.
  static void w(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(_r(message), error: error, stackTrace: stackTrace);

  /// Error — emitted in all builds; also forwarded to [crashSink] in release.
  static void e(Object? message, {Object? error, StackTrace? stackTrace}) {
    final redacted = _r(message);
    _logger.e(redacted, error: error, stackTrace: stackTrace);
    if (kReleaseMode && error != null) {
      crashSink?.recordError(error, stackTrace, redacted);
    }
  }
}
