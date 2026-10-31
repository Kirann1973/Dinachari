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

  test('add, toggle and stream habits', () async {
    final id = await repo.addHabit(name: '  Read  ', emoji: '📖');
    var list = await repo.watchHabits().first;
    expect(list.single.habit.name, 'Read');
    expect(list.single.doneToday, isFalse);

    await repo.toggleToday(id);
    list = await repo.watchHabits().first;
    expect(list.single.doneToday, isTrue);
    expect(list.single.streaks.current, 1);

    await repo.toggleToday(id);
    list = await repo.watchHabits().first;
    expect(list.single.doneToday, isFalse);
  });

  test('back-filled days build a streak', () async {
    final id = await repo.addHabit(name: 'Walk');
    final now = DateTime.now();
    for (var i = 0; i < 4; i++) {
      await repo.setDone(id, true, day: daysBefore(now, i));
    }
    final h = (await repo.watchHabits().first).single;
    expect(h.streaks.current, 4);
    expect(h.completedDays.length, 4);
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

  test('deleting a habit removes its completions', () async {
    final id = await repo.addHabit(name: 'Gone');
    await repo.toggleToday(id);
    await repo.deleteHabit(id);
    expect(await db.select(db.completions).get(), isEmpty);
  });
}
