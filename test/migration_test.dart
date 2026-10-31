import 'package:dinachari/data/database.dart';
import 'package:dinachari/data/habit_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('habits from version 1 survive the upgrade', () async {
    // A database as the first app version created it.
    final raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE habits (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '✅',
        sort_order INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
      );
      CREATE TABLE completions (
        habit_id INTEGER NOT NULL REFERENCES habits (id) ON DELETE CASCADE,
        day TEXT NOT NULL,
        PRIMARY KEY (habit_id, day)
      );
      INSERT INTO habits (name, emoji) VALUES ('Read', '📖');
      INSERT INTO completions (habit_id, day) VALUES (1, '2026-10-30');
      PRAGMA user_version = 1;
    ''');

    final db = AppDatabase(NativeDatabase.opened(raw));
    final repo = HabitRepository(db);
    final h = (await repo.watchHabits().first).single;
    expect(h.habit.name, 'Read');
    expect(h.habit.iconKey, 'check');
    expect(h.habit.kind, HabitKind.check);
    expect(h.target, 1);
    expect(h.completedDays, {'2026-10-30'});
    await db.close();
  });
}
