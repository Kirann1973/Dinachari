import 'package:flutter/widgets.dart';

import '../data/database.dart';
import '../data/habit_repository.dart';
import 'widget_sync.dart';

/// Called by home_widget, in a background isolate, when a habit is tapped on
/// the home-screen widget. The URI looks like `dinachari://toggle?id=3`.
@pragma('vm:entry-point')
Future<void> widgetInteraction(Uri? uri) async {
  final id = int.tryParse(uri?.queryParameters['id'] ?? '');
  if (uri?.host != 'toggle' || id == null) return;

  WidgetsFlutterBinding.ensureInitialized();
  await WidgetSync.init();

  final db = AppDatabase();
  try {
    final repo = HabitRepository(db);
    await repo.toggleToday(id);
    await WidgetSync.push(await repo.watchHabits().first);
  } finally {
    await db.close();
  }
}
