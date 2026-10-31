import 'dart:convert';

import 'package:dinachari/data/database.dart';
import 'package:dinachari/data/habit_repository.dart';
import 'package:dinachari/domain/streaks.dart';
import 'package:dinachari/services/widget_sync.dart';
import 'package:flutter_test/flutter_test.dart';

HabitWithStatus _habit(
  int id,
  String name, {
  bool done = false,
  int streak = 0,
}) => HabitWithStatus(
  habit: Habit(
    id: id,
    name: name,
    emoji: '📖',
    sortOrder: id,
    archived: false,
    createdAt: DateTime(2026),
  ),
  completedDays: const {},
  doneToday: done,
  streaks: StreakStats(current: streak, best: streak),
);

void main() {
  test('payload has the shape the native widgets read', () {
    final json = jsonDecode(
      WidgetSync.buildPayload([
        _habit(1, 'Read', done: true, streak: 4),
        _habit(2, 'Walk'),
      ], now: DateTime(2026, 11, 1, 9)),
    ) as Map<String, dynamic>;

    expect(json['day'], '2026-11-01');
    expect(json['done'], 1);
    expect(json['total'], 2);
    expect(json['habits'], [
      {'id': 1, 'name': 'Read', 'emoji': '📖', 'done': true, 'streak': 4},
      {'id': 2, 'name': 'Walk', 'emoji': '📖', 'done': false, 'streak': 0},
    ]);
  });
}
