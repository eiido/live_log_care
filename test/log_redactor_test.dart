import 'package:flutter_test/flutter_test.dart';
import 'package:live_log_care/live_log_care.dart';

void main() {
  group('LogRedactor', () {
    tearDown(LogRedactor.resetCustomizations);

    test('masks sensitive keys in a map, keeps the rest', () {
      final out =
          LogRedactor.redact({
                'login': 'user@example.com',
                'password': 'secret123',
                'national_id': '1234567890',
              })
              as Map;
      expect(out['login'], 'user@example.com');
      expect(out['password'], LogRedactor.mask);
      expect(out['national_id'], LogRedactor.mask);
    });

    test('recurses into nested maps and lists', () {
      final out =
          LogRedactor.redact({
                'data': [
                  {'token': 'abc', 'name': 'ok'},
                ],
              })
              as Map;
      final inner = (out['data'] as List).first as Map;
      expect(inner['token'], LogRedactor.mask);
      expect(inner['name'], 'ok');
    });

    test('masks sensitive pairs inside free-form strings', () {
      final out = LogRedactor.redact('password: secret; otp=9999') as String;
      expect(out.contains('secret'), isFalse);
      expect(out.contains('9999'), isFalse);
      expect(out.contains(LogRedactor.mask), isTrue);
    });

    test('masks cookie header values but keeps content-type', () {
      final out = LogRedactor.redactHeaders({
        'cookie': 'api_session=abc; session_id=def',
        'content-type': 'application/json',
      });
      expect(out.contains('abc'), isFalse);
      expect(out.contains('def'), isFalse);
      expect(out.contains('application/json'), isTrue);
    });

    test('masks bearer tokens and JWTs', () {
      final bearer =
          LogRedactor.redact('Authorization: Bearer eyJhbGciOi.abc.def')
              as String;
      expect(bearer.contains('eyJhbGciOi'), isFalse);

      final jwt =
          LogRedactor.redact('payload eyJab.cdEf12.ghIj34 end') as String;
      expect(jwt.contains('eyJab.cdEf12.ghIj34'), isFalse);
    });

    test('leaves non-sensitive data intact', () {
      expect(LogRedactor.redact('hello world'), 'hello world');
      expect(LogRedactor.redact(42), 42);
      expect(LogRedactor.redact(null), isNull);
    });

    test('does not over-redact ambiguous substrings (e.g. shipping)', () {
      final out = LogRedactor.redact({'shipping_address': '12 Main St'}) as Map;
      expect(out['shipping_address'], '12 Main St');
    });

    test('honours custom keys', () {
      LogRedactor.addSensitiveKeys(['iban']);
      final out = LogRedactor.redact({'iban': 'DE0000'}) as Map;
      expect(out['iban'], LogRedactor.mask);
    });

    test('honours custom value patterns', () {
      LogRedactor.addValuePatterns([RegExp(r'\b\d{16}\b')]);
      final out = LogRedactor.redact('card 1234567812345678 end') as String;
      expect(out.contains('1234567812345678'), isFalse);
      expect(out.contains(LogRedactor.mask), isTrue);
    });

    test('honours a custom mask', () {
      LogRedactor.mask = '[hidden]';
      final out = LogRedactor.redact({'password': 'x'}) as Map;
      expect(out['password'], '[hidden]');
    });
  });
}
