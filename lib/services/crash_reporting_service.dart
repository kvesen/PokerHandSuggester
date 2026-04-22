import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Lightweight wrapper around Firebase Crashlytics.
///
/// Call [initialize] once during app startup. Then use
/// [recordError] and [recordFlutterError] from error handlers.
///
/// In debug mode, crash reporting is **disabled** so that errors
/// surface naturally in the console without being swallowed.
class CrashReportingService {
  CrashReportingService._();

  static bool _initialized = false;

  /// Initializes Firebase and Crashlytics.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// If Firebase initialization fails (e.g. missing google-services
  /// config files), the error is printed but the app continues
  /// without crash reporting rather than crashing itself.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      // Disable automatic crash collection in debug mode so devs see
      // full stack traces in the console instead of Crashlytics.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      _initialized = true;
    } catch (e, st) {
      // Firebase config files (google-services.json / GoogleService-Info.plist)
      // may not be present yet. Don't crash the app over it.
      debugPrint(
        'CrashReportingService: Firebase init failed — '
        'crash reporting disabled.\n$e\n$st',
      );
    }
  }

  /// Records a non-fatal error. No-op if not initialized or in debug mode.
  static void recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) {
    if (!_initialized || kDebugMode) {
      debugPrint('CrashReportingService (local): $error\n$stack');
      return;
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  /// Records a Flutter framework error as a fatal crash.
  /// No-op if not initialized or in debug mode.
  static void recordFlutterError(FlutterErrorDetails details) {
    if (!_initialized || kDebugMode) {
      debugPrint(
        'CrashReportingService (local): ${details.exceptionAsString()}',
      );
      return;
    }
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }
}
