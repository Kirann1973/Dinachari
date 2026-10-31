import 'package:flutter/material.dart';

import 'ui/today_screen.dart';

/// Colors from the approved mockup: white cards on a deep navy background,
/// orange accent, Space Grotesk numbers and Inter text.
class DC {
  static const background = Color(0xFF1B2030);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF151821);
  static const muted = Color(0xFF4B5263);
  static const faint = Color(0xFF8A91A3);
  static const line = Color(0xFFD5D9E2);
  static const soft = Color(0xFFEEF0F4);
  static const onDark = Color(0xFFC9CED9);
  static const accent = Color(0xFFF97316);
  static const accentDeep = Color(0xFFC2410C);
  static const accentDarker = Color(0xFF9A3412);
  static const accentTint = Color(0xFFFFF1E8);
  static const heat = [
    Color(0xFFEEF0F4),
    Color(0xFFFDBA8C),
    Color(0xFFF97316),
    Color(0xFF9A3412),
  ];

  static const display = 'SpaceGrotesk';
  static const body = 'Inter';
}

/// Darker shade of a habit color, for text on a light tint.
Color deepOf(Color c) => Color.lerp(c, Colors.black, 0.3)!;

class DinachariApp extends StatelessWidget {
  const DinachariApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: DC.accent,
      brightness: Brightness.dark,
    ).copyWith(primary: DC.accent, surface: DC.background);

    return MaterialApp(
      title: 'Dinachari',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        fontFamily: DC.body,
        scaffoldBackgroundColor: DC.background,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: DC.background,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: DC.accentDeep,
          foregroundColor: Colors.white,
        ),
      ),
      home: const TodayScreen(),
    );
  }
}
