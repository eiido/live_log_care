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
  RedactingDioInterceptor({this.logInRelease = false, this.prettyJson = false});

  /// When `true`, requests are also logged (still redacted) in release builds.
  /// Defaults to `false` — network logs are debug-only.
  final bool logInRelease;

  /// When `true`, headers and bodies are rendered as indented JSON instead of
  /// Dart's `Map.toString()`. Pairs with `LiveLogConfig.clean()`.
  final bool prettyJson;

  bool get _active => kDebugMode || logInRelease;

  String _headers(Map<String, dynamic> headers) =>
      prettyJson
          ? LogRedactor.redactJson(headers)
          : LogRedactor.redactHeaders(headers);

  String _body(Object? data) =>
      prettyJson ? LogRedactor.redactJson(data) : LogRedactor.redactBody(data);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_active) {
      LiveLog.d(
        '→ ${options.method} ${options.uri}\n'
        'headers: ${_headers(options.headers)}\n'
        'body: ${_body(options.data)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_active) {
      LiveLog.d(
        '← ${response.statusCode} ${response.requestOptions.uri}\n'
        'body: ${_body(response.data)}',
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
        'body: ${_body(err.response?.data)}',
        error: err,
      );
    }
    handler.next(err);
  }
}
