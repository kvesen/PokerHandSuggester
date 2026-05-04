/// Crash reporting service: centralises non-fatal error reporting.
///
/// This implementation intentionally avoids any external crash-reporting SDK
/// so the app can log errors without adding privacy-sensitive dependencies.
library;

import 'package:flutter/foundation.dart';

/// Records non-fatal errors for diagnostics.
///
/// Uses Flutter's local error pipeline ([FlutterError.reportError]) and, in
/// debug mode, also prints to the console via [debugPrint] and
/// [debugPrintStack].
abstract final class CrashReportingService {
  /// Records [error] and [stackTrace] through Flutter's error pipeline.
  static void recordError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'poker_hand_suggester',
      ),
    );

    if (kDebugMode) {
      debugPrint('Non-fatal error recorded: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
