/// Scrubs sensitive values (passwords, tokens, cookies, OTPs, national IDs,
/// auth headers, card numbers, ...) out of anything before it is logged.
///
/// Used automatically by [LiveLog] on every message and by
/// [RedactingDioInterceptor] on request/response headers and bodies. Redaction
/// is deliberately conservative about false negatives — masking a log line you
/// didn't need to is always preferable to leaking a secret.
///
/// Extend it at startup:
///
/// ```dart
/// LogRedactor.addSensitiveKeys(['iban', 'card_holder']);
/// LogRedactor.addValuePatterns([RegExp(r'\b\d{16}\b')]); // bare card numbers
/// LogRedactor.mask = '[hidden]';
/// ```
abstract final class LogRedactor {
  /// The replacement written in place of any sensitive value.
  static String mask = '***REDACTED***';

  /// Built-in sensitive key names (matched case-insensitively, as substrings).
  /// Curated to avoid common false positives — short/ambiguous tokens such as a
  /// bare `pin` are intentionally excluded; add them yourself if you need them.
  static const Set<String> _defaultKeys = {
    'password', 'passwd', 'passphrase', 'pwd',
    'token', 'access_token', 'refresh_token', 'id_token', 'auth_token',
    'authorization', 'bearer',
    'cookie', 'set-cookie', 'session_id', 'sessionid', 'jsessionid',
    'api_session',
    'national_id', 'nationalid', 'national-id', 'ssn',
    'otp', 'secret', 'client_secret',
    'api_key', 'apikey', 'x-api-key', 'private_key',
    'credit_card', 'card_number', 'cardnumber', 'cvv', 'cvc',
  };

  static final Set<String> _extraKeys = <String>{};

  /// Built-in value patterns always masked inside strings: bearer tokens & JWTs.
  static final List<RegExp> _defaultPatterns = <RegExp>[
    RegExp(r'bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
    RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
  ];

  static final List<RegExp> _extraPatterns = <RegExp>[];

  /// All sensitive key names currently in effect (defaults + custom).
  static Set<String> get sensitiveKeys => {..._defaultKeys, ..._extraKeys};

  /// Add custom sensitive key names (matched case-insensitively, as substrings).
  static void addSensitiveKeys(Iterable<String> keys) =>
      _extraKeys.addAll(keys.map((k) => k.toLowerCase()));

  /// Add custom regex patterns; any match is masked anywhere inside a string.
  static void addValuePatterns(Iterable<RegExp> patterns) =>
      _extraPatterns.addAll(patterns);

  /// Remove all custom keys/patterns and restore the default [mask].
  /// Primarily useful in tests.
  static void resetCustomizations() {
    _extraKeys.clear();
    _extraPatterns.clear();
    mask = '***REDACTED***';
  }

  /// Recursively redact an arbitrary value. Maps/Iterables are walked; keys that
  /// match [sensitiveKeys] have their values masked; strings are scanned for
  /// inline secrets. Other values pass through unchanged.
  static Object? redact(Object? input) {
    if (input == null) return null;
    if (input is Map) return _redactMap(input);
    if (input is Iterable) return input.map(redact).toList();
    if (input is String) return _redactString(input);
    return input;
  }

  /// Redact a header map and return a printable string.
  static String redactHeaders(Map<String, dynamic>? headers) =>
      (headers == null || headers.isEmpty)
          ? '{}'
          : _redactMap(headers).toString();

  /// Redact a request/response body and return a printable string.
  static String redactBody(Object? body) => redact(body).toString();

  static Map<dynamic, dynamic> _redactMap(Map<dynamic, dynamic> source) {
    final result = <dynamic, dynamic>{};
    source.forEach((key, value) {
      result[key] = _isSensitiveKey(key?.toString()) ? mask : redact(value);
    });
    return result;
  }

  static bool _isSensitiveKey(String? key) {
    if (key == null) return false;
    final lower = key.toLowerCase();
    return sensitiveKeys.any((s) => lower == s || lower.contains(s));
  }

  static String _redactString(String input) {
    var output = input;

    // 1) Value patterns first (so a token is gone even when it trails a label
    //    such as "Authorization: Bearer ...").
    for (final pattern in [..._defaultPatterns, ..._extraPatterns]) {
      output = output.replaceAll(pattern, mask);
    }

    // 2) key="value" (JSON) and key=value / key: value (query/header/cookie).
    for (final key in sensitiveKeys) {
      final escaped = RegExp.escape(key);
      output = output.replaceAllMapped(
        RegExp('("?$escaped"?\\s*[:=]\\s*)"[^"]*"', caseSensitive: false),
        (m) => '${m.group(1)}"$mask"',
      );
      output = output.replaceAllMapped(
        RegExp('($escaped\\s*[:=]\\s*)[^;,&\\s"]+', caseSensitive: false),
        (m) => '${m.group(1)}$mask',
      );
    }

    return output;
  }
}
