import 'dart:io';

import '../core.dart';

/// Appends each formatted line to a file. Useful as one branch of a
/// [MultiOutput] (console + file). Call [destroy] to flush and close.
class FileOutput extends LogOutput {
  FileOutput(String path, {bool append = true})
    : _sink = File(
        path,
      ).openWrite(mode: append ? FileMode.append : FileMode.write);

  final IOSink _sink;

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      _sink.writeln(line);
    }
  }

  @override
  Future<void> destroy() async {
    await _sink.flush();
    await _sink.close();
  }
}
