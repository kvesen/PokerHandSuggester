import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/theme_service.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // TODO: Send to crash reporting service (e.g., Sentry, Crashlytics)
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      // TODO: Send to crash reporting service
      debugPrint('PlatformDispatcher error: $error\n$stack');
      return true;
    };

    // Make status bar transparent for a modern edge-to-edge look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    final themeService = await ThemeService.create();
    runApp(PokerHandSuggesterApp(themeService: themeService));
  }, (error, stack) {
    // TODO: Send to crash reporting service
    debugPrint('Uncaught error: $error\n$stack');
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
      title: 'Poker Hand Suggester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D58), // Vibrant modern green
          brightness: Brightness.light,
          surface: const Color(0xFFF8F9FA),
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Or any modern sans-serif
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1CE885), // Neon accent
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
          background: const Color(0xFF090B0F), // Deep premium dark
        ),
        useMaterial3: true,
      ),
      themeMode: widget.themeService.themeMode,
      home: HomeScreen(themeService: widget.themeService),
    );
  }
}
