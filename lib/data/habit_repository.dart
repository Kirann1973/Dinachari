import 'package:drift/drift.dart';

import '../domain/day.dart';
import '../domain/streaks.dart';
import 'database.dart';

/// A habit together with what the UI needs to show it.
class HabitWithStatus {
  const HabitWithStatus({
    required this.habit,
    required this.completedDays,
    required this.doneToday,
    required this.streaks,
  });

  final Habit habit;
  final Set<String> completedDays;
  final bool doneToday;
  final StreakStats streaks;
}

/// All reads and writes for habits go through here.
class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  /// Active habits with their completion history, updated live.
  Stream<List<HabitWithStatus>> watchHabits({DateTime Function()? clock}) {
    final habitsQuery = _db.select(_db.habits)
      ..where((h) => h.archived.equals(false))
      ..orderBy([
        (h) => OrderingTerm.asc(h.sortOrder),
        (h) => OrderingTerm.asc(h.id),
      ]);

    final query = habitsQuery.join([
      leftOuterJoin(
        _db.completions,
        _db.completions.habitId.equalsExp(_db.habits.id),
      ),
    ]);

    return query.watch().map((rows) {
      final today = dayKey((clock ?? DateTime.now)());
      final habits = <int, Habit>{};
      final days = <int, Set<String>>{};
      for (final row in rows) {
        final habit = row.readTable(_db.habits);
        habits[habit.id] = habit;
        final days0 = days.putIfAbsent(habit.id, () => <String>{});
        final completion = row.readTableOrNull(_db.completions);
        if (completion != null) days0.add(completion.day);
      }
      return habits.values.map((habit) {
        final done = days[habit.id] ?? <String>{};
        return HabitWithStatus(
          habit: habit,
          completedDays: done,
          doneToday: done.contains(today),
          streaks: computeStreaks(done, today: parseDayKey(today)),
        );
      }).toList();
    });
  }

  Future<int> addHabit({required String name, String emoji = '✅'}) async {
    final maxOrder = _db.habits.sortOrder.max();
    final row = await (_db.selectOnly(_db.habits)..addColumns([maxOrder]))
        .getSingle();
    final next = (row.read(maxOrder) ?? -1) + 1;
    return _db.into(_db.habits).insert(
          HabitsCompanion.insert(
            name: name.trim(),
            emoji: Value(emoji),
            sortOrder: Value(next),
          ),
        );
  }

  Future<void> updateHabit(int id, {String? name, String? emoji}) {
    return (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        emoji: emoji == null ? const Value.absent() : Value(emoji),
      ),
    );
  }

  Future<void> archiveHabit(int id) {
    return (_db.update(_db.habits)..where((h) => h.id.equals(id)))
        .write(const HabitsCompanion(archived: Value(true)));
  }

  Future<void> deleteHabit(int id) {
    return (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();
  }

  /// Marks or unmarks [habitId] as done on [day] (defaults to today).
  Future<void> setDone(int habitId, bool done, {DateTime? day}) async {
    final key = dayKey(day ?? DateTime.now());
    if (done) {
      await _db.into(_db.completions).insertOnConflictUpdate(
            CompletionsCompanion.insert(habitId: habitId, day: key),
          );
    } else {
      await (_db.delete(_db.completions)
            ..where((c) => c.habitId.equals(habitId) & c.day.equals(key)))
          .go();
    }
  }

  Future<void> toggleToday(int habitId) async {
    final key = dayKey(DateTime.now());
    final existing = await (_db.select(_db.completions)
          ..where((c) => c.habitId.equals(habitId) & c.day.equals(key)))
        .getSingleOrNull();
    await setDone(habitId, existing == null);
  }
}
