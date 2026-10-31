import '../data/habit_repository.dart';
import 'day.dart';

/// Share of due habits done on [day] (0..1), or null if nothing was due
/// and nothing was done.
double? dayScore(List<HabitWithStatus> habits, DateTime day) {
  final key = dayKey(day);
  var due = 0;
  var done = 0;
  for (final h in habits) {
    final isDue = h.dueOn(day);
    final isDone = h.doneOn(key);
    if (isDue || isDone) due++;
    if (isDone) done++;
  }
  if (due == 0) return null;
  return done / due;
}

/// The plant grows one step for each day in a row where at least half of
/// that day's habits were done. Days with nothing due are skipped, and today
/// only counts against it once it's over.
class PlantState {
  const PlantState({required this.growthDays, required this.bestGrowthDays});

  final int growthDays;
  final int bestGrowthDays;

  static const goodDayShare = 0.5;

  /// Days needed for each level: seed, sprout, seedling, young plant,
  /// bushy plant, in bloom.
  static const levelDays = [0, 1, 3, 7, 14, 30];
  static const levelNames = [
    'Seed',
    'Sprout',
    'Seedling',
    'Young plant',
    'Bushy plant',
    'In bloom',
  ];

  int get level {
    var l = 0;
    for (var i = 0; i < levelDays.length; i++) {
      if (growthDays >= levelDays[i]) l = i;
    }
    return l;
  }

  String get levelName => levelNames[level];
  bool get isMaxLevel => level == levelDays.length - 1;
  int get daysToNext => isMaxLevel ? 0 : levelDays[level + 1] - growthDays;
  String get nextName => isMaxLevel ? levelName : levelNames[level + 1];

  /// Progress from this level to the next, 0..1.
  double get progress {
    if (isMaxLevel) return 1;
    final from = levelDays[level];
    final to = levelDays[level + 1];
    return (growthDays - from) / (to - from);
  }

  static PlantState of(List<HabitWithStatus> habits, {DateTime? today}) {
    final now = dateOnly(today ?? DateTime.now());
    if (habits.isEmpty) {
      return const PlantState(growthDays: 0, bestGrowthDays: 0);
    }
    final start = habits
        .map((h) => dateOnly(h.habit.createdAt))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestDone = habits
        .expand((h) => h.dayValues.keys)
        .map(parseDayKey)
        .fold<DateTime>(start, (a, b) => b.isBefore(a) ? b : a);

    var run = 0;
    var best = 0;
    for (
      var d = earliestDone;
      !d.isAfter(now);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final score = dayScore(habits, d);
      if (score == null) continue;
      if (score >= goodDayShare) {
        run++;
        if (run > best) best = run;
      } else if (d != now) {
        run = 0;
      }
    }
    return PlantState(growthDays: run, bestGrowthDays: best);
  }
}
