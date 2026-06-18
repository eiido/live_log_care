/// A pluggable destination for `error`-level logs in **release** builds.
///
/// Implement this to forward errors to Firebase Crashlytics, Sentry, or any
/// other backend, then register it once at startup — either directly or via
/// [LiveLogConfig.crashSink]:
///
/// ```dart
/// LiveLog.crashSink = MyCrashlyticsSink();
/// ```
///
/// `live_log_care` itself depends on no crash-reporting package, so apps that
/// don't use one simply leave the sink `null`.
abstract interface class CrashSink {
  /// Forward a captured [error] (with optional [stackTrace] and an already
  /// redacted [context] message) to the crash-reporting backend.
  void recordError(Object error, StackTrace? stackTrace, Object? context);
}
