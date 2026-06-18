import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'live_log.dart';
import 'log_redactor.dart';

/// A redaction-safe replacement for `PrettyDioLogger` / `LogInterceptor`.
///
/// Headers and bodies are passed through [LogRedactor], and by default nothing
/// is logged in release. Add it last in the interceptor chain:
///
/// ```dart
/// dio.interceptors.add(RedactingDioInterceptor());
/// ```
class RedactingDioInterceptor extends Interceptor {
  RedactingDioInterceptor({this.logInRelease = false});

  /// When `true`, requests are also logged (still redacted) in release builds.
  /// Defaults to `false` — network logs are debug-only.
  final bool logInRelease;

  bool get _active => kDebugMode || logInRelease;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_active) {
      LiveLog.d(
        '→ ${options.method} ${options.uri}\n'
        'headers: ${LogRedactor.redactHeaders(options.headers)}\n'
        'body: ${LogRedactor.redactBody(options.data)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (_active) {
      LiveLog.d(
        '← ${response.statusCode} ${response.requestOptions.uri}\n'
        'body: ${LogRedactor.redactBody(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_active) {
      LiveLog.e(
        '✗ ${err.requestOptions.method} ${err.requestOptions.uri} '
        '(${err.response?.statusCode})\n'
        'body: ${LogRedactor.redactBody(err.response?.data)}',
        error: err,
      );
    }
    handler.next(err);
  }
}
