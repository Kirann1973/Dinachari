import 'package:drift/drift.dart';

import '../domain/day.dart';
import '../domain/schedule.dart';
import '../domain/streaks.dart';
import 'database.dart';

/// A habit together with what the UI needs to show it.
class HabitWithStatus {
  const HabitWithStatus({
    required this.habit,
    required this.dayValues,
    required this.today,
  });

  final Habit habit;

  /// Progress per `yyyy-MM-dd` day (only days with progress are present).
  final Map<String, int> dayValues;

  /// Today's `yyyy-MM-dd` key when this was loaded.
  final String today;

  int get target => habit.target < 1 ? 1 : habit.target;
  bool get isCount => habit.kind == HabitKind.count;

  int get todayValue => dayValues[today] ?? 0;
  bool get doneToday => todayValue >= target;

  /// Days on which the habit was fully done.
  Set<String> get completedDays => {
    for (final e in dayValues.entries)
      if (e.value >= target) e.key,
  };

  Schedule get schedule => Schedule(habit.days);
  bool dueOn(DateTime day) => schedule.on(day);
  bool get dueToday => dueOn(parseDayKey(today));

  bool doneOn(String day) => (dayValues[day] ?? 0) >= target;

  StreakStats get streaks =>
      computeStreaks(completedDays, today: parseDayKey(today), isDue: dueOn);

  /// The streak ignoring today, so the widget can add today's tick itself.
  int get streakBeforeToday => computeStreaks(
    completedDays..remove(today),
    today: parseDayKey(today),
    isDue: dueOn,
  ).current;

  /// Share of due days in the last [days] days (including today) that were
  /// done. Today only counts once it's done.
  double consistency({int days = 30}) {
    final now = parseDayKey(today);
    var due = 0;
    var hits = 0;
    for (var i = 0; i < days; i++) {
      final d = daysBefore(now, i);
      final done = doneOn(dayKey(d));
      if (done) hits++;
      if (dueOn(d) && (i > 0 || done)) due++;
    }
    if (due == 0) return 0;
    return (hits / due).clamp(0, 1).toDouble();
  }
}

/// All reads and writes for habits go through here.
class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  /// Active habits with their progress history, updated live.
  Stream<List<HabitWithStatus>> watchHabits({
    DateTime Function()? clock,
    bool archived = false,
  }) {
    final habitsQuery = _db.select(_db.habits)
      ..where((h) => h.archived.equals(archived))
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
      final values = <int, Map<String, int>>{};
      for (final row in rows) {
        final habit = row.readTable(_db.habits);
        habits[habit.id] = habit;
        final map = values.putIfAbsent(habit.id, () => <String, int>{});
        final c = row.readTableOrNull(_db.completions);
        if (c != null) map[c.day] = c.value;
      }
      return [
        for (final habit in habits.values)
          HabitWithStatus(
            habit: habit,
            dayValues: values[habit.id] ?? const {},
            today: today,
          ),
      ];
    });
  }

  Future<int> addHabit({
    required String name,
    String iconKey = 'icon:check_circle',
    int color = 0xFFF97316,
    HabitKind kind = HabitKind.check,
    int target = 1,
    String unit = '',
    int days = 127,
    String sound = 'default',
  }) async {
    final maxOrder = _db.habits.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.habits,
    )..addColumns([maxOrder])).getSingle();
    final next = (row.read(maxOrder) ?? -1) + 1;
    return _db
        .into(_db.habits)
        .insert(
          HabitsCompanion.insert(
            name: name.trim(),
            iconKey: Value(iconKey),
            color: Value(color),
            kind: Value(kind),
            target: Value(kind == HabitKind.check ? 1 : target.clamp(1, 999)),
            unit: Value(kind == HabitKind.check ? '' : unit.trim()),
            days: Value(days),
            sound: Value(sound),
            sortOrder: Value(next),
          ),
        );
  }

  Future<void> updateHabit(
    int id, {
    required String name,
    required String iconKey,
    required int color,
    required HabitKind kind,
    required int target,
    required String unit,
    required int days,
    required String sound,
  }) {
    return (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        name: Value(name.trim()),
        iconKey: Value(iconKey),
        color: Value(color),
        kind: Value(kind),
        target: Value(kind == HabitKind.check ? 1 : target.clamp(1, 999)),
        unit: Value(kind == HabitKind.check ? '' : unit.trim()),
        days: Value(days),
        sound: Value(sound),
      ),
    );
  }

  Future<void> archiveHabit(int id, {bool archived = true}) {
    return (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(archived: Value(archived)),
    );
  }

  Future<void> restoreHabit(int id) => archiveHabit(id, archived: false);

  /// Reminders of one habit, earliest first.
  Stream<List<Reminder>> watchReminders(int habitId) {
    return (_db.select(_db.reminders)
          ..where((r) => r.habitId.equals(habitId))
          ..orderBy([(r) => OrderingTerm.asc(r.minute)]))
        .watch();
  }

  /// Replaces all reminders of [habitId].
  Future<void> setReminders(int habitId, List<RemindersCompanion> list) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.reminders,
      )..where((r) => r.habitId.equals(habitId))).go();
      for (final r in list) {
        await _db
            .into(_db.reminders)
            .insert(
              r.copyWith(id: const Value.absent(), habitId: Value(habitId)),
            );
      }
    });
  }

  /// Every reminder of an active habit, with its habit, for scheduling.
  Stream<List<(Habit, Reminder)>> watchAllReminders() {
    final query = _db.select(_db.reminders).join([
      innerJoin(_db.habits, _db.habits.id.equalsExp(_db.reminders.habitId)),
    ])..where(_db.habits.archived.equals(false));
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (row.readTable(_db.habits), row.readTable(_db.reminders)),
      ],
    );
  }

  Future<void> deleteHabit(int id) {
    return (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();
  }

  /// Sets progress for [habitId] on [day] (defaults to today). 0 clears it.
  Future<void> setValue(int habitId, int value, {DateTime? day}) =>
      setValueForKey(habitId, value, dayKey(day ?? DateTime.now()));

  Future<void> setValueForKey(int habitId, int value, String key) async {
    if (value <= 0) {
      await (_db.delete(
        _db.completions,
      )..where((c) => c.habitId.equals(habitId) & c.day.equals(key))).go();
    } else {
      await _db
          .into(_db.completions)
          .insertOnConflictUpdate(
            CompletionsCompanion.insert(
              habitId: habitId,
              day: key,
              value: Value(value),
            ),
          );
    }
  }

  /// Marks a day fully done or not done.
  Future<void> setDone(int habitId, bool done, {DateTime? day}) async {
    final habit = await (_db.select(
      _db.habits,
    )..where((h) => h.id.equals(habitId))).getSingleOrNull();
    if (habit == null) return;
    await setValue(habitId, done ? habit.target : 0, day: day);
  }

  Future<int> _todayValue(int habitId) async {
    final row =
        await (_db.select(_db.completions)..where(
              (c) =>
                  c.habitId.equals(habitId) &
                  c.day.equals(dayKey(DateTime.now())),
            ))
            .getSingleOrNull();
    return row?.value ?? 0;
  }

  /// Tick or untick today for a done/not-done habit.
  Future<void> toggleToday(int habitId) async {
    final habit = await (_db.select(
      _db.habits,
    )..where((h) => h.id.equals(habitId))).getSingleOrNull();
    if (habit == null) return;
    final value = await _todayValue(habitId);
    await setValue(habitId, value >= habit.target ? 0 : habit.target);
  }

  /// Adds [delta] to today's count (never below 0).
  Future<void> addToToday(int habitId, int delta) async {
    final value = await _todayValue(habitId);
    await setValue(habitId, (value + delta).clamp(0, 999));
  }
}
