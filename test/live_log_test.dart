import 'package:flutter_test/flutter_test.dart';
import 'package:live_log_care/live_log_care.dart';

void main() {
  group('LiveLog', () {
    tearDown(() => LiveLog.configure(const LiveLogConfig()));

    test('logs at every level without throwing, with redaction', () {
      LiveLog.configure(const LiveLogConfig());
      expect(() => LiveLog.t('trace'), returnsNormally);
      expect(() => LiveLog.i('info'), returnsNormally);
      expect(() => LiveLog.d({'password': 'x'}), returnsNormally);
      expect(
        () => LiveLog.e(
          'boom',
          error: StateError('x'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('disabled config silences logging without throwing', () {
      LiveLog.configure(const LiveLogConfig(enabled: false));
      expect(() => LiveLog.w('quiet'), returnsNormally);
    });

    test('redaction is active by default', () {
      LiveLog.configure(const LiveLogConfig());
      expect(LiveLog.redactionActive, isTrue);
    });

    test('revealSecretsInDebug disables redaction in debug builds', () {
      // Tests run in debug mode (kDebugMode == true).
      LiveLog.configure(const LiveLogConfig(revealSecretsInDebug: true));
      expect(LiveLog.redactionActive, isFalse);
    });

    test('redactionEnabled:false disables redaction entirely', () {
      LiveLog.configure(const LiveLogConfig(redactionEnabled: false));
      expect(LiveLog.redactionActive, isFalse);
    });
  });
}
