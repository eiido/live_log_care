import 'package:flutter_bloc/flutter_bloc.dart';

import 'live_log.dart';

/// A [BlocObserver] that routes all Bloc/Cubit lifecycle and error events
/// through [LiveLog], so they are automatically build-mode gated and redacted.
///
/// Register once at startup:
///
/// ```dart
/// Bloc.observer = LiveLogBlocObserver();
/// ```
class LiveLogBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    LiveLog.t('onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    LiveLog.t('onChange -- ${bloc.runtimeType}, $change');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    LiveLog.e(
      'onError -- ${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    LiveLog.t('onClose -- ${bloc.runtimeType}');
  }
}
