import 'dart:io';

import 'package:dinachari/data/database.dart';
import 'package:dinachari/data/habit_repository.dart';
import 'package:dinachari/domain/day.dart';
import 'package:dinachari/ui/insight_cards.dart';
import 'package:dinachari/ui/widget_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _load(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  setUpAll(() async {
    await _load('Inter', [
      for (final w in ['400', '500', '600', '700']) 'assets/fonts/Inter-$w.ttf',
    ]);
    await _load('SpaceGrotesk', [
      for (final w in ['500', '700']) 'assets/fonts/SpaceGrotesk-$w.ttf',
    ]);
  });

  final today = dateOnly(DateTime.now());
  final habits = [
    HabitWithStatus(
      habit: Habit(
        id: 1,
        name: 'Gym',
        emoji: '',
        iconKey: 'emoji:💪',
        color: 0xFFF97316,
        kind: HabitKind.check,
        target: 1,
        unit: '',
        sortOrder: 0,
        archived: false,
        days: 127,
        sound: 'default',
        createdAt: daysBefore(today, 60),
      ),
      dayValues: {for (var i = 0; i < 20; i++) dayKey(daysBefore(today, i)): 1},
      today: dayKey(today),
    ),
  ];

  for (final image in WidgetImage.values) {
    testWidgets('${image.name} card fits its widget image', (tester) async {
      await tester.pumpWidget(
        UnconstrainedBox(child: image.build(habits, measuring: true)),
      );
      final card = tester.getSize(
        find.byWidgetPredicate(
          (w) =>
              w is WeekChartCard || w is AllHabitsHeatmapCard || w is PlantCard,
        ),
      );
      // ignore: avoid_print
      print('${image.name}: ${card.height} of ${image.height}');
      expect(tester.takeException(), isNull);
      expect(card.height, lessThanOrEqualTo(image.height));
      expect(card.height, greaterThan(image.height - 24));
    });
  }
}
