import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'core.dart';

/// The default output: writes each line to the console via [debugPrint], so it
/// shows up wherever your app's normal logs do (terminal, Logcat, Debug
/// Console). Multi-line boxes render exactly as today.
class ConsoleOutput extends LogOutput {
  const ConsoleOutput();

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      debugPrint(line);
    }
  }
}

/// Writes each log as a single `dart:developer` event.
///
/// Emitting one event per log (rather than one per line) keeps multi-line JSON
/// as a single, copyable block in the VS Code Debug Console — and
/// `developer.log` output is not tagged with the `I/flutter (PID):` prefix that
/// `print`-based output carries.
class DevLogOutput extends LogOutput {
  const DevLogOutput({this.name = 'live_log'});

  /// The `name` shown by the Debug Console / DevTools for each entry.
  final String name;

  // Maps onto `dart:developer` severities so DevTools' Logging view can filter.
  static const Map<LogLevel, int> _levels = {
    LogLevel.trace: 500,
    LogLevel.debug: 700,
    LogLevel.info: 800,
    LogLevel.warning: 900,
    LogLevel.error: 1000,
    LogLevel.fatal: 1200,
  };

  @override
  void output(OutputEvent event) {
    developer.log(
      event.lines.join('\n'),
      name: name,
      level: _levels[event.level] ?? 0,
    );
  }
}

/// Fans a single [OutputEvent] out to several [outputs] — e.g. log to the
/// console and a file at once.
class MultiOutput extends LogOutput {
  const MultiOutput(this.outputs);

  final List<LogOutput> outputs;

  @override
  void output(OutputEvent event) {
    for (final out in outputs) {
      out.output(event);
    }
  }

  @override
  Future<void> destroy() async {
    for (final out in outputs) {
      await out.destroy();
    }
  }
}
