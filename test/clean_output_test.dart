import 'package:flutter_test/flutter_test.dart';
import 'package:live_log_care/live_log_care.dart';

void main() {
  group('LogRedactor.prettyJson / redactJson', () {
    tearDown(LogRedactor.resetCustomizations);

    test('renders a map as indented JSON', () {
      final out = LogRedactor.prettyJson({'a': 1, 'b': 'x'});
      expect(out, '{\n  "a": 1,\n  "b": "x"\n}');
    });

    test('redactJson masks secrets before encoding', () {
      final out = LogRedactor.redactJson({'password': 'hunter2', 'ok': 1});
      expect(out.contains('hunter2'), isFalse);
      expect(out.contains(LogRedactor.mask), isTrue);
      expect(out.contains('"ok": 1'), isTrue);
    });

    test('falls back to toString for non-encodable values', () {
      // A bare object JSON cannot encode; must not throw.
      final out = LogRedactor.prettyJson(Object());
      expect(out, isA<String>());
    });
  });

  group('CleanPrinter', () {
    test('formats a map message as JSON, no box border', () {
      final lines = const CleanPrinter().log(
        LogEvent(LogLevel.debug, {'id': 6, 'name': 'Test Qard'}),
      );
      expect(lines.first, '[D] {');
      expect(lines.any((l) => l.contains('"name": "Test Qard"')), isTrue);
      expect(lines.any((l) => l.contains('┌') || l.contains('│')), isFalse);
    });

    test('appends error and stack trace lines', () {
      final lines = const CleanPrinter(includeLevel: false).log(
        LogEvent(
          LogLevel.error,
          'boom',
          error: StateError('bad'),
          stackTrace: StackTrace.fromString('frame0\nframe1'),
        ),
      );
      expect(lines.first, 'boom');
      expect(lines.any((l) => l.startsWith('error: ')), isTrue);
      expect(lines.contains('frame0'), isTrue);
    });
  });

  group('BoxedPrinter', () {
    test('wraps content in a border (no ANSI when colors off)', () {
      final lines = const BoxedPrinter(
        colors: false,
      ).log(LogEvent(LogLevel.info, 'hello'));
      expect(lines.first.startsWith('┌'), isTrue);
      expect(lines.any((l) => l == '│ hello'), isTrue);
      expect(lines.last.startsWith('└'), isTrue);
      expect(lines.any((l) => l.contains('\x1B[')), isFalse);
    });

    test('adds a divider and stack frames for errors', () {
      final lines = const BoxedPrinter(colors: false).log(
        LogEvent(
          LogLevel.error,
          'boom',
          error: StateError('bad'),
          stackTrace: StackTrace.fromString('#0 a\n#1 b'),
        ),
      );
      expect(lines.any((l) => l.startsWith('├')), isTrue);
      expect(lines.any((l) => l.contains('error: ')), isTrue);
    });
  });

  group('ThresholdFilter', () {
    test('emits at or above the threshold, blocks below', () {
      const filter = ThresholdFilter(LogLevel.warning);
      expect(filter.shouldLog(LogEvent(LogLevel.error, 'x')), isTrue);
      expect(filter.shouldLog(LogEvent(LogLevel.warning, 'x')), isTrue);
      expect(filter.shouldLog(LogEvent(LogLevel.info, 'x')), isFalse);
    });

    test('off threshold blocks everything', () {
      const filter = ThresholdFilter(LogLevel.off);
      expect(filter.shouldLog(LogEvent(LogLevel.fatal, 'x')), isFalse);
    });
  });

  group('MultiOutput', () {
    test('fans an event out to every child output', () {
      final a = _RecordingOutput();
      final b = _RecordingOutput();
      MultiOutput([
        a,
        b,
      ]).output(OutputEvent(LogEvent(LogLevel.info, 'hi'), const ['hi']));
      expect(a.received, ['hi']);
      expect(b.received, ['hi']);
    });
  });
}

class _RecordingOutput extends LogOutput {
  final List<String> received = [];

  @override
  void output(OutputEvent event) => received.addAll(event.lines);
}
