import 'core.dart';
import 'log_redactor.dart';

/// Renders `Map`/`Iterable` messages as indented JSON, everything else via
/// `toString()`. Shared by both bundled printers.
String _renderMessage(Object? message) =>
    (message is Map || message is Iterable)
        ? LogRedactor.prettyJson(message)
        : message.toString();

/// The default printer: a bordered, color-coded box — the familiar
/// "pretty" log look. `Map`/`Iterable` messages are shown as indented JSON.
///
/// ```
/// ┌──────────────────────────────
/// │ → GET /api/profile
/// └──────────────────────────────
/// ```
class BoxedPrinter extends LogPrinter {
  const BoxedPrinter({
    this.colors = true,
    this.printTime = false,
    this.errorMethodCount = 8,
    this.lineLength = 120,
  });

  /// Wrap each line in ANSI color escapes keyed off the level.
  final bool colors;

  /// Prepend an ISO-8601 timestamp line.
  final bool printTime;

  /// Maximum stack-trace frames to show for an event that carries one.
  final int errorMethodCount;

  /// Width of the top/bottom borders.
  final int lineLength;

  // ANSI 256 foreground codes per level (grey → red → pink).
  static const Map<LogLevel, int> _fg = {
    LogLevel.trace: 244,
    LogLevel.debug: 39,
    LogLevel.info: 12,
    LogLevel.warning: 208,
    LogLevel.error: 196,
    LogLevel.fatal: 199,
  };

  String _paint(String text, LogLevel level) =>
      colors ? '\x1B[38;5;${_fg[level] ?? 15}m$text\x1B[0m' : text;

  @override
  List<String> log(LogEvent event) {
    final content = <String>[
      if (printTime) 'time: ${event.time.toIso8601String()}',
      ..._renderMessage(event.message).split('\n'),
    ];

    final hasDetail = event.error != null || event.stackTrace != null;
    final detail = <String>[
      if (event.error != null) 'error: ${event.error}',
      if (event.stackTrace != null && errorMethodCount > 0)
        ..._formatStack(event.stackTrace!),
    ];

    final top = '┌${'─' * (lineLength - 1)}';
    final divider = '├${'┄' * (lineLength - 1)}';
    final bottom = '└${'─' * (lineLength - 1)}';

    return <String>[
      _paint(top, event.level),
      for (final line in content) _paint('│ $line', event.level),
      if (hasDetail) _paint(divider, event.level),
      for (final line in detail) _paint('│ $line', event.level),
      _paint(bottom, event.level),
    ];
  }

  List<String> _formatStack(StackTrace stackTrace) =>
      stackTrace
          .toString()
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .take(errorMethodCount)
          .toList();
}

/// A borderless, color-free printer. `Map`/`Iterable` messages render as
/// indented JSON; any error/stack trace is appended on its own lines.
///
/// Pair with `DevLogOutput` — both are wired up by `LiveLogConfig.clean()` —
/// for prefix-free, copy-friendly output in the VS Code Debug Console.
class CleanPrinter extends LogPrinter {
  const CleanPrinter({this.includeLevel = true});

  /// Prefix each entry with a short level tag, e.g. `[D]`.
  final bool includeLevel;

  static const Map<LogLevel, String> _tags = {
    LogLevel.trace: 'T',
    LogLevel.debug: 'D',
    LogLevel.info: 'I',
    LogLevel.warning: 'W',
    LogLevel.error: 'E',
    LogLevel.fatal: 'F',
  };

  @override
  List<String> log(LogEvent event) {
    final buffer = StringBuffer();
    if (includeLevel) buffer.write('[${_tags[event.level] ?? '?'}] ');
    buffer.write(_renderMessage(event.message));
    if (event.error != null) buffer.write('\nerror: ${event.error}');
    if (event.stackTrace != null) buffer.write('\n${event.stackTrace}');

    return buffer.toString().split('\n');
  }
}
