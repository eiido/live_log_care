// Conditional entry point for FileOutput.
//
// On platforms with `dart:io` the real implementation is used; everywhere else
// (web/WASM) a stub that throws UnsupportedError. Crucially — unlike some
// logging packages — the stub imports no `dart:io`, so it stays
// WASM-compatible.
export 'file_output_stub.dart' if (dart.library.io) 'file_output_io.dart';
