import 'dart:convert';

import 'package:dinachari/data/database.dart';
import 'package:dinachari/data/habit_repository.dart';
import 'package:dinachari/services/widget_sync.dart';
import 'package:flutter_test/flutter_test.dart';

HabitWithStatus _habit(
  int id,
  String name, {
  HabitKind kind = HabitKind.check,
  int target = 1,
  Map<String, int> values = const {},
}) => HabitWithStatus(
  habit: Habit(
    id: id,
    name: name,
    emoji: '',
    iconKey: 'gym',
    color: 0xFFF97316,
    kind: kind,
    target: target,
    unit: kind == HabitKind.count ? 'glasses' : '',
    sortOrder: id,
    archived: false,
    createdAt: DateTime(2026),
  ),
  dayValues: values,
  today: '2026-11-01',
);

void main() {
  test('payload has the shape the native widget reads', () {
    final json = jsonDecode(
      WidgetSync.buildPayload([
        _habit(
          1,
          'Gym',
          values: {'2026-11-01': 1, '2026-10-31': 1, '2026-10-30': 1},
        ),
        _habit(
          2,
          'Water',
          kind: HabitKind.count,
          target: 8,
          values: {'2026-11-01': 5},
        ),
      ], now: DateTime(2026, 11, 1, 9)),
    ) as Map<String, dynamic>;

    expect(json['day'], '2026-11-01');
    expect(json['habits'], [
      {
        'id': 1,
        'name': 'Gym',
        'icon': WidgetSync.iconImageKey('gym', 0xFFF97316),
        'color': 0xFFF97316,
        'kind': 'check',
        'target': 1,
        'unit': '',
        'value': 1,
        'streakBefore': 2,
      },
      {
        'id': 2,
        'name': 'Water',
        'icon': WidgetSync.iconImageKey('gym', 0xFFF97316),
        'color': 0xFFF97316,
        'kind': 'count',
        'target': 8,
        'unit': 'glasses',
        'value': 5,
        'streakBefore': 0,
      },
    ]);
  });

  test('widget taps queue is parsed, bad data ignored', () {
    expect(WidgetSync.parsePending('[{"id":3,"day":"2026-11-01","value":1}]'), [
      (id: 3, day: '2026-11-01', value: 1),
    ]);
    expect(WidgetSync.parsePending('not json'), isEmpty);
    expect(WidgetSync.parsePending(null), isEmpty);
  });
}
