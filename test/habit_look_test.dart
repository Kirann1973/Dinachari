import 'dart:io';

import 'package:dinachari/domain/habit_look.dart';
import 'package:dinachari/domain/symbols.dart';
import 'package:dinachari/services/widget_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    SymbolCatalog.debugSet(
      SymbolCatalog.fromJson(File('assets/icons.json').readAsStringSync()),
    );
  });

  test('stored looks round-trip', () {
    for (final s in [
      'emoji:🛁🧴',
      'icon:fitness_center',
      'photo:/data/x.jpg',
      'text:GY',
    ]) {
      expect(HabitLook.parse(s).stored, s);
    }
  });

  test('old fixed icon keys still work', () {
    expect((HabitLook.parse('gym') as IconLook).name, 'fitness_center');
    expect((HabitLook.parse('bath') as IconLook).name, 'bathtub');
    expect((HabitLook.parse('check') as IconLook).name, 'check_circle');
    expect((HabitLook.parse('unknown') as IconLook).name, 'check_circle');
  });

  test('combos keep at most 3 emoji, counting skin tones as one', () {
    expect(HabitLook.limit('🛁🧴🧼🪥'), '🛁🧴🧼');
    expect(HabitLook.limit('🏋🏽‍♂️💪'), '🏋🏽‍♂️💪');
  });

  test('icon search finds habits by everyday words', () {
    final catalog = SymbolCatalog.instance;
    expect(catalog.icons.length, greaterThan(3000));
    expect(
      catalog.search('gym').map((i) => i.name),
      contains('fitness_center'),
    );
    expect(catalog.search('bath').map((i) => i.name), contains('bathtub'));
    expect(catalog.search('zzzqqq'), isEmpty);
  });

  test('a new habit name suggests a matching icon', () {
    expect(suggestLook('Gym'), 'icon:fitness_center');
    expect(suggestLook('Morning bath'), 'icon:bathtub');
    expect(suggestLook('Drink water'), 'icon:water_drop');
    expect(suggestLook(''), 'icon:check_circle');
  });

  test('widget image keys are stable and file-name safe', () {
    final a = WidgetSync.iconImageKey('emoji:🛁🧴', 0xFFF97316);
    expect(a, WidgetSync.iconImageKey('emoji:🛁🧴', 0xFFF97316));
    expect(a, matches(RegExp(r'^look_[0-9a-f]+_[0-9a-f]+$')));
    expect(a, isNot(WidgetSync.iconImageKey('emoji:🛁', 0xFFF97316)));
  });
}
