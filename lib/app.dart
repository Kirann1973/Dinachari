import 'package:flutter/material.dart';

import 'ui/today_screen.dart';

/// Colors from the approved widget mockups: white cards on a dark
/// background with an orange accent.
class DinachariColors {
  static const background = Color(0xFF121212);
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFF7A1A);
  static const textOnCard = Color(0xFF1A1A1A);
  static const mutedOnCard = Color(0xFF8A8A8A);
}

class DinachariApp extends StatelessWidget {
  const DinachariApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: DinachariColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: DinachariColors.accent,
      surface: DinachariColors.background,
    );

    return MaterialApp(
      title: 'Dinachari',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: DinachariColors.background,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: DinachariColors.background,
          elevation: 0,
          centerTitle: false,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: DinachariColors.accent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const TodayScreen(),
    );
  }
}
