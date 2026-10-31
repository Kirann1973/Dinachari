import 'day.dart';

/// Streak numbers for one habit.
class StreakStats {
  const StreakStats({required this.current, required this.best});

  /// Consecutive completed days ending today. If today is not done yet, the
  /// streak ending yesterday still counts, so a streak doesn't look broken
  /// first thing in the morning.
  final int current;

  /// Longest run of consecutive completed days ever.
  final int best;
}

/// Computes streaks from a set of completed `yyyy-MM-dd` day keys.
StreakStats computeStreaks(Set<String> completedDays, {DateTime? today}) {
  final now = dateOnly(today ?? DateTime.now());

  var current = 0;
  var cursor = completedDays.contains(dayKey(now)) ? now : daysBefore(now, 1);
  while (completedDays.contains(dayKey(cursor))) {
    current++;
    cursor = daysBefore(cursor, 1);
  }

  final sorted = completedDays.map(parseDayKey).toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? prev;
  for (final day in sorted) {
    if (prev != null && dayKey(daysBefore(day, 1)) == dayKey(prev)) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
    prev = day;
  }

  return StreakStats(current: current, best: best < current ? current : best);
}
