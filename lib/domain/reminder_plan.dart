import 'day.dart';
import 'schedule.dart';

/// A reminder as the editor and scheduler see it.
class ReminderRule {
  const ReminderRule({required this.minute, this.every = 0, this.endMinute});

  /// Minutes after midnight of the (first) reminder.
  final int minute;

  /// Repeat every this many minutes until [endMinute]; 0 = once a day.
  final int every;
  final int? endMinute;

  bool get repeats => every > 0 && endMinute != null && endMinute! > minute;

  /// All times of day (minutes after midnight) this rule fires.
  List<int> get times {
    if (!repeats) return [minute];
    return [for (var m = minute; m <= endMinute!; m += every) m];
  }

  String get label {
    if (!repeats) return formatMinute(minute);
    final h = every ~/ 60;
    final m = every % 60;
    final step = h == 0 ? '$m min' : (m == 0 ? '$h h' : '$h h $m min');
    return 'Every $step, ${formatMinute(minute)}–${formatMinute(endMinute!)}';
  }
}

String formatMinute(int minute) {
  final h = (minute ~/ 60).toString().padLeft(2, '0');
  final m = (minute % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder(this.habitId, this.at);
  final int habitId;
  final DateTime at;
}

/// Works out the next reminders to schedule, from [now] for [horizonDays].
///
/// Skips days the habit isn't due, and skips the rest of today once the
/// habit is done. Returns at most [max] (Android allows ~500 alarms).
List<PlannedReminder> planReminders({
  required List<
    ({int habitId, Schedule schedule, bool doneToday, List<ReminderRule> rules})
  >
  habits,
  required DateTime now,
  int horizonDays = 14,
  int max = 400,
}) {
  final out = <PlannedReminder>[];
  final today = dateOnly(now);
  for (var d = 0; d < horizonDays; d++) {
    final day = DateTime(today.year, today.month, today.day + d);
    for (final h in habits) {
      if (!h.schedule.on(day)) continue;
      if (d == 0 && h.doneToday) continue;
      for (final rule in h.rules) {
        for (final t in rule.times) {
          final at = DateTime(day.year, day.month, day.day, t ~/ 60, t % 60);
          if (at.isAfter(now)) out.add(PlannedReminder(h.habitId, at));
        }
      }
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.take(max).toList();
}

/// Built-in reminder sounds (files in android/app/src/main/res/raw).
const builtInSounds = {
  'chime': 'Chime',
  'bell': 'Bell',
  'ding': 'Ding',
  'pop': 'Pop',
  'marimba': 'Marimba',
  'rise': 'Rise',
};

/// Readable name of a stored sound value.
String soundLabel(String sound) {
  if (sound == 'default') return 'Phone default';
  if (sound == 'silent') return 'Silent';
  if (sound.startsWith('raw:')) {
    return builtInSounds[sound.substring(4)] ?? sound.substring(4);
  }
  if (sound.startsWith('uri:')) {
    final bar = sound.lastIndexOf('|');
    return bar > 0 ? sound.substring(bar + 1) : 'Phone sound';
  }
  return 'Phone default';
}
