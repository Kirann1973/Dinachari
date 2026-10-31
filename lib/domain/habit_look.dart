import 'package:flutter/widgets.dart' show StringCharacters;

import 'symbols.dart';

/// What a habit looks like: any emoji (up to 3 combined), any of ~4,000
/// icons, a photo, or a few letters.
///
/// Stored in the habit's `iconKey` column as `emoji:🛁🧴`, `icon:bathtub`,
/// `photo:/path/to/file.jpg` or `text:GY`. Plain keys from version 0.2
/// (like `gym`) still work and map to the matching icon.
sealed class HabitLook {
  const HabitLook();

  factory HabitLook.parse(String stored) {
    final i = stored.indexOf(':');
    if (i > 0) {
      final kind = stored.substring(0, i);
      final value = stored.substring(i + 1);
      switch (kind) {
        case 'emoji':
          if (value.isNotEmpty) return EmojiLook(value);
        case 'icon':
          if (value.isNotEmpty) return IconLook(value);
        case 'photo':
          if (value.isNotEmpty) return PhotoLook(value);
        case 'text':
          if (value.isNotEmpty) return TextLook(value);
      }
    }
    return IconLook(_legacyIcons[stored] ?? 'check_circle');
  }

  String get stored;

  /// How many emoji or letters can be combined.
  static const maxParts = 3;

  /// Keeps at most [maxParts] characters (an emoji with skin tone counts once).
  static String limit(String s) => s.trim().characters.take(maxParts).string;
}

class EmojiLook extends HabitLook {
  const EmojiLook(this.emoji);
  final String emoji;
  @override
  String get stored => 'emoji:$emoji';
}

class IconLook extends HabitLook {
  const IconLook(this.name);
  final String name;
  SymbolIcon? get symbol => SymbolCatalog.instance.byName(name);
  @override
  String get stored => 'icon:$name';
}

class PhotoLook extends HabitLook {
  const PhotoLook(this.path);
  final String path;
  @override
  String get stored => 'photo:$path';
}

class TextLook extends HabitLook {
  const TextLook(this.text);
  final String text;
  @override
  String get stored => 'text:$text';
}

/// Picks a starting look from the habit's name: "Bath" → bathtub icon.
String suggestLook(String name) {
  final words = name
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.length >= 3)
      .toList();
  for (final w in words) {
    final alias = _aliases[w];
    if (alias != null) return 'icon:$alias';
  }
  // The main word is usually last ("Morning bath", "Evening walk").
  for (final w in words.reversed) {
    final hits = SymbolCatalog.instance.search(w, limit: 1);
    if (hits.isNotEmpty) return 'icon:${hits.first.name}';
  }
  return 'icon:check_circle';
}

/// Words the icon tags don't cover well.
const _aliases = {
  'gym': 'fitness_center',
  'workout': 'fitness_center',
  'bath': 'bathtub',
  'water': 'water_drop',
  'drink': 'water_drop',
  'meditate': 'self_improvement',
  'meditation': 'self_improvement',
  'read': 'menu_book',
  'reading': 'menu_book',
  'run': 'directions_run',
  'walk': 'directions_walk',
  'sleep': 'bedtime',
  'pray': 'temple_hindu',
  'puja': 'temple_hindu',
  'journal': 'edit_note',
  'study': 'school',
  'teeth': 'dentistry',
  'smoke': 'smoke_free',
  'sugar': 'no_food',
};

/// The fixed icon keys from version 0.2.
const _legacyIcons = {
  'check': 'check_circle',
  'gym': 'fitness_center',
  'bath': 'bathtub',
  'shower': 'shower',
  'water': 'water_drop',
  'meditate': 'self_improvement',
  'read': 'menu_book',
  'run': 'directions_run',
  'walk': 'directions_walk',
  'cycle': 'pedal_bike',
  'swim': 'pool',
  'yoga': 'spa',
  'sleep': 'bedtime',
  'wake': 'wb_sunny',
  'food': 'restaurant',
  'fruit': 'eco',
  'nosugar': 'no_food',
  'coffee': 'local_cafe',
  'pill': 'medication',
  'teeth': 'clean_hands',
  'study': 'school',
  'code': 'code',
  'journal': 'edit_note',
  'music': 'music_note',
  'art': 'brush',
  'language': 'translate',
  'pray': 'temple_hindu',
  'clean': 'cleaning_services',
  'money': 'savings',
  'nophone': 'phonelink_off',
  'smokefree': 'smoke_free',
  'call': 'call',
  'plant': 'local_florist',
  'pet': 'pets',
  'heart': 'favorite',
  'star': 'star',
};
