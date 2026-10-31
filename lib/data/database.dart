import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// How a habit is tracked.
enum HabitKind {
  /// Done or not done each day (e.g. Gym, Bath).
  check,

  /// Counted up to a daily target (e.g. 8 glasses of water).
  count,
}

/// A habit the user wants to do every day.
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Unused since schema 2 (replaced by [iconKey]); kept so old data loads.
  TextColumn get emoji => text().withDefault(const Constant('✅'))();

  /// The habit's look, e.g. `emoji:🛁` or `icon:bathtub`
  /// (see lib/domain/habit_look.dart).
  TextColumn get iconKey =>
      text().withDefault(const Constant('icon:check_circle'))();

  /// ARGB color of the habit.
  IntColumn get color => integer().withDefault(const Constant(0xFFF97316))();
  IntColumn get kind => intEnum<HabitKind>().withDefault(const Constant(0))();

  /// Daily target. Always 1 for [HabitKind.check].
  IntColumn get target => integer().withDefault(const Constant(1))();

  /// Unit for counted habits, e.g. "glasses".
  TextColumn get unit => text().withDefault(const Constant(''))();

  /// Days the habit is due, as bits: Monday = 1, Tuesday = 2 … Sunday = 64.
  /// 127 = every day (see lib/domain/schedule.dart).
  IntColumn get days => integer().withDefault(const Constant(127))();

  /// Reminder sound: `default`, `silent`, `raw:<name>` (built in) or
  /// `uri:<content uri>|<title>` (a sound picked from the phone).
  TextColumn get sound => text().withDefault(const Constant('default'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per habit per day with progress. `day` is a `yyyy-MM-dd` key.
/// A day counts as done when `value >= target`.
class Completions extends Table {
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get day => text()();
  IntColumn get value => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {habitId, day};
}

/// A reminder for a habit: one time a day, or every [every] minutes from
/// [minute] until [endMinute]. Minutes are counted from midnight.
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get minute => integer()();

  /// 0 for a single time a day.
  IntColumn get every => integer().withDefault(const Constant(0))();
  IntColumn get endMinute => integer().nullable()();
}

@DriftDatabase(tables: [Habits, Completions, Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'dinachari'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(habits, habits.iconKey);
        await m.addColumn(habits, habits.color);
        await m.addColumn(habits, habits.kind);
        await m.addColumn(habits, habits.target);
        await m.addColumn(habits, habits.unit);
        await m.addColumn(completions, completions.value);
      }
      if (from < 3) {
        await m.addColumn(habits, habits.days);
        await m.addColumn(habits, habits.sound);
        await m.createTable(reminders);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
