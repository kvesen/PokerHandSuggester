import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/crash_reporting_service.dart';
import 'services/theme_service.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize crash reporting (gracefully no-ops if Firebase config
    // files are missing — see CrashReportingService for details).
    await CrashReportingService.initialize();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      CrashReportingService.recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      CrashReportingService.recordError(error, stack, fatal: true);
      return true;
    };

    try {
      await Hive.initFlutter();
    } catch (e, st) {
      // History features will be unavailable but the app can still run.
      debugPrint('Hive init failed — history features disabled.\n$e\n$st');
      CrashReportingService.recordError(e, st);
    }

    // Make status bar transparent for a modern edge-to-edge look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    ThemeService themeService;
    try {
      themeService = await ThemeService.create();
    } catch (e, st) {
      debugPrint('ThemeService init failed — using system defaults.\n$e\n$st');
      CrashReportingService.recordError(e, st);
      themeService = ThemeService.systemDefault();
    }
    runApp(PokerHandSuggesterApp(themeService: themeService));
  }, (error, stack) {
    CrashReportingService.recordError(error, stack, fatal: true);
  });
}

class PokerHandSuggesterApp extends StatefulWidget {
  const PokerHandSuggesterApp({super.key, required this.themeService});

  final ThemeService themeService;

  @override
  State<PokerHandSuggesterApp> createState() => _PokerHandSuggesterAppState();
}

class _PokerHandSuggesterAppState extends State<PokerHandSuggesterApp> {
  @override
  void initState() {
    super.initState();
    widget.themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D58), // Vibrant modern green
          brightness: Brightness.light,
          surface: const Color(0xFFF8F9FA),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1CE885), // Neon accent
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        useMaterial3: true,
      ),
      themeMode: widget.themeService.themeMode,
      home: HomeScreen(themeService: widget.themeService),
    );
  }
}
