import 'package:dinachari/data/database.dart';
import 'package:dinachari/data/habit_repository.dart';
import 'package:dinachari/domain/day.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HabitRepository(db);
  });

  tearDown(() => db.close());

  test('add, toggle and stream a tick habit', () async {
    final id = await repo.addHabit(name: '  Gym  ', iconKey: 'gym');
    var list = await repo.watchHabits().first;
    expect(list.single.habit.name, 'Gym');
    expect(list.single.habit.iconKey, 'gym');
    expect(list.single.doneToday, isFalse);

    await repo.toggleToday(id);
    list = await repo.watchHabits().first;
    expect(list.single.doneToday, isTrue);
    expect(list.single.streaks.current, 1);
    expect(list.single.streakBeforeToday, 0);

    await repo.toggleToday(id);
    list = await repo.watchHabits().first;
    expect(list.single.doneToday, isFalse);
  });

  test('counted habit is done only when it reaches its goal', () async {
    final id = await repo.addHabit(
      name: 'Water',
      kind: HabitKind.count,
      target: 3,
      unit: 'glasses',
    );
    await repo.addToToday(id, 1);
    await repo.addToToday(id, 1);
    var h = (await repo.watchHabits().first).single;
    expect(h.todayValue, 2);
    expect(h.doneToday, isFalse);

    await repo.addToToday(id, 1);
    h = (await repo.watchHabits().first).single;
    expect(h.doneToday, isTrue);
    expect(h.habit.unit, 'glasses');

    await repo.addToToday(id, -5);
    h = (await repo.watchHabits().first).single;
    expect(h.todayValue, 0);
  });

  test('back-filled days build a streak', () async {
    final id = await repo.addHabit(name: 'Walk');
    final now = DateTime.now();
    for (var i = 0; i < 4; i++) {
      await repo.setDone(id, true, day: daysBefore(now, i));
    }
    final h = (await repo.watchHabits().first).single;
    expect(h.streaks.current, 4);
    expect(h.streakBeforeToday, 3);
    expect(h.completedDays.length, 4);
  });

  test('editing changes icon, color and type', () async {
    final id = await repo.addHabit(name: 'Bath');
    await repo.updateHabit(
      id,
      name: 'Bath',
      iconKey: 'bath',
      color: 0xFF1D4ED8,
      kind: HabitKind.check,
      target: 5,
      unit: 'ignored',
    );
    final h = (await repo.watchHabits().first).single.habit;
    expect(h.iconKey, 'bath');
    expect(h.color, 0xFF1D4ED8);
    expect(h.target, 1, reason: 'tick habits always have a goal of 1');
    expect(h.unit, '');
  });

  test('new habits go to the end, archived ones are hidden', () async {
    final a = await repo.addHabit(name: 'A');
    await repo.addHabit(name: 'B');
    expect((await repo.watchHabits().first).map((h) => h.habit.name), [
      'A',
      'B',
    ]);
    await repo.archiveHabit(a);
    expect((await repo.watchHabits().first).map((h) => h.habit.name), ['B']);
  });

  test('deleting a habit removes its history', () async {
    final id = await repo.addHabit(name: 'Gone');
    await repo.toggleToday(id);
    await repo.deleteHabit(id);
    expect(await db.select(db.completions).get(), isEmpty);
  });
}
