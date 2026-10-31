import 'package:flutter/material.dart';

/// Icons a habit can use, by stable key (the key is what gets stored).
const Map<String, IconData> habitIcons = {
  'check': Icons.check_circle_outline,
  'gym': Icons.fitness_center,
  'bath': Icons.bathtub_outlined,
  'shower': Icons.shower_outlined,
  'water': Icons.water_drop_outlined,
  'meditate': Icons.self_improvement,
  'read': Icons.menu_book_outlined,
  'run': Icons.directions_run,
  'walk': Icons.directions_walk,
  'cycle': Icons.pedal_bike,
  'swim': Icons.pool,
  'yoga': Icons.spa_outlined,
  'sleep': Icons.bedtime_outlined,
  'wake': Icons.wb_sunny_outlined,
  'food': Icons.restaurant,
  'fruit': Icons.eco_outlined,
  'nosugar': Icons.no_food_outlined,
  'coffee': Icons.local_cafe_outlined,
  'pill': Icons.medication_outlined,
  'teeth': Icons.clean_hands_outlined,
  'study': Icons.school_outlined,
  'code': Icons.code,
  'journal': Icons.edit_note,
  'music': Icons.music_note_outlined,
  'art': Icons.brush_outlined,
  'language': Icons.translate,
  'pray': Icons.temple_hindu_outlined,
  'clean': Icons.cleaning_services_outlined,
  'money': Icons.savings_outlined,
  'nophone': Icons.phonelink_off,
  'smokefree': Icons.smoke_free,
  'call': Icons.call_outlined,
  'plant': Icons.local_florist_outlined,
  'pet': Icons.pets,
  'heart': Icons.favorite_outline,
  'star': Icons.star_outline,
};

IconData habitIcon(String key) => habitIcons[key] ?? Icons.check_circle_outline;

/// Habit colors. Each is dark enough for white text and icons on top.
const List<Color> habitColors = [
  Color(0xFFF97316), // orange
  Color(0xFF1D4ED8), // blue
  Color(0xFF16A34A), // green
  Color(0xFF0D9488), // teal
  Color(0xFF7C3AED), // purple
  Color(0xFFDB2777), // pink
  Color(0xFFDC2626), // red
  Color(0xFFCA8A04), // amber
];

/// A light tint of [c] for backgrounds behind the habit's icon.
Color tintOf(Color c) =>
    Color.alphaBlend(c.withValues(alpha: 0.12), Colors.white);

/// Guesses an icon from a habit's name, so "Gym" or "Bath" start with the
/// right icon before the user picks one.
String suggestIconKey(String name) {
  final n = name.toLowerCase();
  const hints = {
    'gym': 'gym',
    'workout': 'gym',
    'exercise': 'gym',
    'lift': 'gym',
    'bath': 'bath',
    'shower': 'shower',
    'water': 'water',
    'drink': 'water',
    'meditat': 'meditate',
    'read': 'read',
    'book': 'read',
    'run': 'run',
    'jog': 'run',
    'walk': 'walk',
    'step': 'walk',
    'cycl': 'cycle',
    'bike': 'cycle',
    'swim': 'swim',
    'yoga': 'yoga',
    'sleep': 'sleep',
    'bed': 'sleep',
    'wake': 'wake',
    'early': 'wake',
    'eat': 'food',
    'fruit': 'fruit',
    'veg': 'fruit',
    'sugar': 'nosugar',
    'coffee': 'coffee',
    'tea': 'coffee',
    'pill': 'pill',
    'vitamin': 'pill',
    'medic': 'pill',
    'teeth': 'teeth',
    'brush': 'teeth',
    'floss': 'teeth',
    'study': 'study',
    'learn': 'study',
    'code': 'code',
    'journal': 'journal',
    'write': 'journal',
    'diary': 'journal',
    'music': 'music',
    'guitar': 'music',
    'piano': 'music',
    'draw': 'art',
    'paint': 'art',
    'language': 'language',
    'pray': 'pray',
    'puja': 'pray',
    'clean': 'clean',
    'save': 'money',
    'money': 'money',
    'phone': 'nophone',
    'screen': 'nophone',
    'smok': 'smokefree',
    'call': 'call',
    'plant': 'plant',
    'dog': 'pet',
    'cat': 'pet',
  };
  for (final e in hints.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return 'check';
}
