import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/habit_repository.dart';
import 'services/reminders.dart';
import 'services/widget_sync.dart';

/// The app database. Overridden with an in-memory database in tests.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(ref.watch(databaseProvider)),
);

/// Active habits with today's status. Ticks made on the home-screen widget
/// are applied first, and every change is pushed back to the widget.
final habitsProvider = StreamProvider<List<HabitWithStatus>>((ref) async* {
  final repo = ref.watch(habitRepositoryProvider);
  await WidgetSync.applyPending(repo);
  await for (final habits in repo.watchHabits()) {
    WidgetSync.push(habits);
    yield habits;
  }
});

/// Archived habits, for the Archived section.
final archivedHabitsProvider = StreamProvider<List<HabitWithStatus>>(
  (ref) => ref.watch(habitRepositoryProvider).watchHabits(archived: true),
);

/// Every reminder with its habit.
final allRemindersProvider = StreamProvider<List<(Habit, Reminder)>>(
  (ref) => ref.watch(habitRepositoryProvider).watchAllReminders(),
);

/// Rebooks notifications whenever habits or reminders change. Watched by the
/// app shell so it stays alive while the app runs.
final reminderSchedulerProvider = Provider<void>((ref) {
  final habits = ref.watch(habitsProvider).value;
  final reminders = ref.watch(allRemindersProvider).value;
  if (habits == null || reminders == null) return;
  ReminderService.instance.reschedule(habits, reminders);
});
