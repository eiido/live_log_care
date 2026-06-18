import 'package:flutter/foundation.dart';

/// Severity levels, ordered by [weight] (lower = more verbose).
///
/// Re-exported as `LogLevel` so you can configure logging without importing
/// anything else. Member names match the common logging convention.
enum LogLevel {
  trace(1000),
  debug(2000),
  info(3000),
  warning(4000),
  error(5000),
  fatal(6000),

  /// Sentinel above every real level; used as a threshold to silence all logs.
  off(10000);

  const LogLevel(this.weight);

  /// Relative severity. A log is emitted when its level's weight is `>=` the
  /// active threshold's weight.
  final int weight;
}

/// A single log record handed to a [LogPrinter].
@immutable
class LogEvent {
  LogEvent(
    this.level,
    this.message, {
    this.error,
    this.stackTrace,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  final LogLevel level;
  final Object? message;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime time;
}

/// The formatted [lines] a [LogPrinter] produced for an [origin] event, handed
/// to a [LogOutput].
@immutable
class OutputEvent {
  const OutputEvent(this.origin, this.lines);

  final LogEvent origin;
  final List<String> lines;

  LogLevel get level => origin.level;
}

/// Decides whether a [LogEvent] is emitted at all. Implement for custom gating
/// (e.g. sampling, per-tag rules); the default is [ThresholdFilter].
abstract class LogFilter {
  const LogFilter();

  bool shouldLog(LogEvent event);
}

/// Emits an event only when its level is at or above [min].
class ThresholdFilter extends LogFilter {
  const ThresholdFilter(this.min);

  final LogLevel min;

  @override
  bool shouldLog(LogEvent event) => event.level.weight >= min.weight;
}

/// Formats a [LogEvent] into the lines that a [LogOutput] will write.
/// Implement for a fully custom look; bundled options are `BoxedPrinter`
/// (the default) and `CleanPrinter`.
abstract class LogPrinter {
  const LogPrinter();

  List<String> log(LogEvent event);
}

/// Receives formatted [OutputEvent]s and writes them somewhere (console, a
/// file, a crash backend, several at once). Bundled options are
/// `ConsoleOutput` (the default), `DevLogOutput`, `MultiOutput` and
/// `FileOutput`.
abstract class LogOutput {
  const LogOutput();

  void output(OutputEvent event);

  /// Flush/close any resources. Called by [MultiOutput] on its children.
  Future<void> destroy() async {}
}
