import 'package:dinachari/data/database.dart';
import 'package:dinachari/data/habit_repository.dart';
import 'package:dinachari/domain/day.dart';
import 'package:dinachari/domain/plant.dart';
import 'package:dinachari/domain/reminder_plan.dart';
import 'package:dinachari/domain/schedule.dart';
import 'package:dinachari/domain/streaks.dart';
import 'package:flutter_test/flutter_test.dart';

// 2026-11-02 is a Monday.
final monday = DateTime(2026, 11, 2);
DateTime day(int offset) => DateTime(2026, 11, 2 + offset);

HabitWithStatus habit(
  int id, {
  int days = 127,
  Iterable<int> done = const [],
}) => HabitWithStatus(
  habit: Habit(
    id: id,
    name: 'H$id',
    emoji: '',
    iconKey: 'emoji:✅',
    color: 0xFFF97316,
    kind: HabitKind.check,
    target: 1,
    unit: '',
    sortOrder: id,
    archived: false,
    days: days,
    sound: 'default',
    createdAt: day(-30),
  ),
  dayValues: {for (final d in done) dayKey(day(d)): 1},
  today: dayKey(day(0)),
);

void main() {
  group('Schedule', () {
    test('presets and labels', () {
      expect(Schedule.weekdays.on(monday), isTrue);
      expect(Schedule.weekdays.on(day(5)), isFalse); // Saturday
      expect(Schedule.weekends.on(day(6)), isTrue); // Sunday
      expect(Schedule.everyDay.label, 'Every day');
      expect(
        const Schedule(0).toggle(1).toggle(3).toggle(5).label,
        'Mon, Wed, Fri',
      );
    });
  });

  group('streaks with days off', () {
    test('weekend days off do not break a weekday streak', () {
      // Done Thu, Fri last week and Mon this week.
      final s = computeStreaks(
        {dayKey(day(-4)), dayKey(day(-3)), dayKey(day(0))},
        today: monday,
        isDue: Schedule.weekdays.on,
      );
      expect(s.current, 3);
    });

    test('a missed due day breaks it', () {
      final s = computeStreaks(
        {dayKey(day(-4)), dayKey(day(0))},
        today: monday,
        isDue: Schedule.weekdays.on,
      );
      expect(s.current, 1);
      expect(s.best, 1);
    });
  });

  group('planReminders', () {
    final rules = [const ReminderRule(minute: 9 * 60)];

    test('skips today once done, and days off', () {
      final plan = planReminders(
        habits: [
          (
            habitId: 1,
            schedule: Schedule.weekdays,
            doneToday: true,
            rules: rules,
          ),
        ],
        now: DateTime(2026, 11, 2, 7),
        horizonDays: 7,
      );
      // Tue..Fri only: today is done and the weekend is off.
      expect(plan.map((p) => p.at.day), [3, 4, 5, 6]);
    });

    test('repeating reminders fill the window and drop past times', () {
      const rule = ReminderRule(minute: 8 * 60, every: 120, endMinute: 14 * 60);
      expect(rule.times, [480, 600, 720, 840]);
      expect(rule.label, 'Every 2 h, 08:00–14:00');
      final plan = planReminders(
        habits: [
          (
            habitId: 1,
            schedule: Schedule.everyDay,
            doneToday: false,
            rules: [rule],
          ),
        ],
        now: DateTime(2026, 11, 2, 11),
        horizonDays: 1,
      );
      expect(plan.map((p) => p.at.hour), [12, 14]);
    });

    test('respects the cap', () {
      final plan = planReminders(
        habits: [
          (
            habitId: 1,
            schedule: Schedule.everyDay,
            doneToday: false,
            rules: [const ReminderRule(minute: 0, every: 15, endMinute: 1439)],
          ),
        ],
        now: DateTime(2026, 11, 2),
        max: 50,
      );
      expect(plan, hasLength(50));
    });
  });

  group('plant', () {
    test('grows with good days and resets after a bad one', () {
      final habits = [
        habit(1, done: [-5, -4, -3, -2, -1]),
        habit(2, done: [-2, -1]),
      ];
      // Each of the last 5 days had at least half done.
      final p = PlantState.of(habits, today: day(0));
      expect(p.growthDays, 5);
      expect(p.levelName, 'Seedling');
      expect(p.daysToNext, 2);

      final broken = [
        habit(1, done: [-5, -4, -1]),
        habit(2, done: [-1]),
      ];
      expect(PlantState.of(broken, today: day(0)).growthDays, 1);
      expect(PlantState.of(broken, today: day(0)).bestGrowthDays, 2);
    });

    test('days with nothing due are skipped', () {
      final habits = [
        habit(1, days: Schedule.weekdays.mask, done: [-4, -3, 0]),
      ];
      expect(PlantState.of(habits, today: day(0)).growthDays, 3);
    });
  });
}
