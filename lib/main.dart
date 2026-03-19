import 'package:flutter/material.dart';

import 'services/theme_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeService = await ThemeService.create();
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
      title: 'Poker Hand Suggester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D3B0D),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: widget.themeService.themeMode,
      home: HomeScreen(themeService: widget.themeService),
    );
  }
}
