import '../core.dart';

/// Web/WASM stub. Imports no `dart:io`, so it never drags platform code into a
/// web build; constructing it throws to make the unsupported use obvious.
class FileOutput extends LogOutput {
  FileOutput(String path, {bool append = true}) {
    throw UnsupportedError('FileOutput is not supported on this platform.');
  }

  @override
  void output(OutputEvent event) =>
      throw UnsupportedError('FileOutput is not supported on this platform.');
}
