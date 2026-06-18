import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:live_log_care/live_log_care.dart';

void main() {
  // 1) Configure once (optional — secure defaults apply without this).
  LiveLog.configure(const LiveLogConfig(releaseLevel: LogLevel.error));

  // 2) Teach the redactor about app-specific secrets.
  LogRedactor.addSensitiveKeys(['iban', 'card_holder']);

  // 3) Route Bloc/Cubit events through LiveLog.
  Bloc.observer = LiveLogBlocObserver();

  // 4) Use a redaction-safe Dio logger instead of a raw one.
  final dio = Dio()..interceptors.add(RedactingDioInterceptor());

  LiveLog.i('app started');
  // The password is masked automatically:
  LiveLog.d({'login': 'user@example.com', 'password': 'hunter2'});

  runApp(ExampleApp(dio: dio));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, required this.dio});

  final Dio dio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'live_log_care',
      home: Scaffold(
        appBar: AppBar(title: const Text('live_log_care')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              try {
                throw StateError('boom');
              } catch (e, s) {
                LiveLog.e('button tap failed', error: e, stackTrace: s);
              }
            },
            child: const Text('Log a redacted error'),
          ),
        ),
      ),
    );
  }
}
