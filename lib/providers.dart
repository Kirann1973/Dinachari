import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/habit_repository.dart';
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

/// Active habits with today's status. Every change is also pushed to the
/// home-screen widget.
final habitsProvider = StreamProvider<List<HabitWithStatus>>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.watchHabits().map((habits) {
    WidgetSync.push(habits);
    return habits;
  });
});
