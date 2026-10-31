import 'day.dart';

/// Streak numbers for one habit.
class StreakStats {
  const StreakStats({required this.current, required this.best});

  /// Done days in a row up to today. Days the habit isn't due are skipped
  /// (they don't break a streak), and today only breaks it once it's over.
  final int current;

  /// Longest such run ever.
  final int best;
}

/// Computes streaks from completed `yyyy-MM-dd` day keys.
///
/// [isDue] says whether the habit is scheduled on a day; by default every day.
StreakStats computeStreaks(
  Set<String> completedDays, {
  DateTime? today,
  bool Function(DateTime day)? isDue,
}) {
  if (completedDays.isEmpty) return const StreakStats(current: 0, best: 0);
  final now = dateOnly(today ?? DateTime.now());
  final due = isDue ?? (_) => true;

  final earliest = completedDays
      .map(parseDayKey)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  var run = 0;
  var best = 0;
  // Walk forward one calendar day at a time (DST safe).
  for (
    var d = earliest;
    !d.isAfter(now);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    if (completedDays.contains(dayKey(d))) {
      run++;
      if (run > best) best = run;
    } else if (due(d) && d != now) {
      run = 0;
    }
  }
  return StreakStats(current: run, best: best);
}
