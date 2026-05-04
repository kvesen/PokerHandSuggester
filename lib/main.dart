import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
  } catch (e, st) {
    // History features will be unavailable but the app can still run.
    debugPrint('Hive init failed — history features disabled.\n$e\n$st');
  }

  // Make status bar transparent for a modern edge-to-edge look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  ThemeService themeService;
  try {
    themeService = await ThemeService.create();
  } catch (e, st) {
    debugPrint(
      'ThemeService init failed — using system defaults.\n$e\n$st',
    );
    themeService = ThemeService.systemDefault();
  }
  runApp(PokerHandSuggesterApp(themeService: themeService));
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: widget.themeService.themeMode,
      home: HomeScreen(themeService: widget.themeService),
    );
  }
}
