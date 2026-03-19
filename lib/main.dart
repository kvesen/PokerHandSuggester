import 'package:flutter/material.dart';

import 'ui/screens/home_screen.dart';

void main() {
  runApp(const PokerHandSuggesterApp());
}

class PokerHandSuggesterApp extends StatelessWidget {
  const PokerHandSuggesterApp({super.key});

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
      home: const HomeScreen(),
    );
  }
}
