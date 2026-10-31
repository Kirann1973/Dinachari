import 'dart:convert';

import 'package:flutter/services.dart';

/// One icon from the Material Symbols set (Apache 2.0, bundled as a font).
class SymbolIcon {
  const SymbolIcon(this.name, this.codepoint, this.tags);

  final String name;
  final int codepoint;

  /// Space-separated search words, e.g. "barbell dumbbell exercise gym".
  final String tags;

  String get glyph => String.fromCharCode(codepoint);
}

/// The ~4,000 searchable icons in assets/icons.json, most popular first.
///
/// Icons are drawn as text in the `MaterialSymbolsRounded` font rather than
/// as `IconData`, so release builds can keep shrinking Flutter's own icons.
class SymbolCatalog {
  SymbolCatalog._(this.icons) : _byName = {for (final i in icons) i.name: i};

  static const fontFamily = 'MaterialSymbolsRounded';

  final List<SymbolIcon> icons;
  final Map<String, SymbolIcon> _byName;

  static SymbolCatalog? _instance;

  /// The loaded catalog, or an empty one before [load] finishes.
  static SymbolCatalog get instance => _instance ?? SymbolCatalog._(const []);

  static Future<SymbolCatalog> load([AssetBundle? bundle]) async {
    if (_instance != null) return _instance!;
    final raw = await (bundle ?? rootBundle).loadString('assets/icons.json');
    return _instance = fromJson(raw);
  }

  static SymbolCatalog fromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return SymbolCatalog._([
      for (final e in list.cast<List<dynamic>>())
        SymbolIcon(e[0] as String, e[1] as int, e[2] as String),
    ]);
  }

  /// For tests.
  static void debugSet(SymbolCatalog? catalog) => _instance = catalog;

  SymbolIcon? byName(String name) => _byName[name];

  /// Icons whose name or tags match every word of [query].
  List<SymbolIcon> search(String query, {int limit = 300}) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      // Habit-friendly icons first, then everything else by popularity.
      final first = [for (final n in habitFavorites) ?_byName[n]];
      final firstSet = first.toSet();
      return [
        ...first,
        ...icons.where((i) => !firstSet.contains(i)),
      ].take(limit).toList();
    }

    final exact = <SymbolIcon>[];
    final rest = <SymbolIcon>[];
    for (final icon in icons) {
      final name = icon.name.replaceAll('_', ' ');
      final haystack = '$name ${icon.tags}';
      if (!words.every(haystack.contains)) continue;
      (words.every(name.contains) ? exact : rest).add(icon);
      if (exact.length >= limit) break;
    }
    return [...exact, ...rest].take(limit).toList();
  }
}

/// Shown first in the icon picker before the user searches.
const habitFavorites = [
  'fitness_center',
  'bathtub',
  'shower',
  'water_drop',
  'self_improvement',
  'menu_book',
  'directions_run',
  'directions_walk',
  'directions_bike',
  'pool',
  'sports_gymnastics',
  'sports_martial_arts',
  'hiking',
  'bedtime',
  'wb_sunny',
  'alarm',
  'restaurant',
  'nutrition',
  'local_cafe',
  'no_food',
  'medication',
  'dentistry',
  'spa',
  'favorite',
  'psychology',
  'mood',
  'school',
  'code',
  'edit_note',
  'translate',
  'music_note',
  'piano',
  'brush',
  'photo_camera',
  'temple_hindu',
  'mosque',
  'church',
  'cleaning_services',
  'local_laundry_service',
  'savings',
  'payments',
  'phonelink_off',
  'smoke_free',
  'no_drinks',
  'call',
  'groups',
  'family_restroom',
  'pets',
  'local_florist',
  'yard',
  'eco',
  'recycling',
  'timer',
  'checklist',
  'check_circle',
  'star',
  'emoji_events',
  'bolt',
  'local_fire_department',
];
