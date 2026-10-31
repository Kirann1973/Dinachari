import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'domain/symbols.dart';
import 'services/reminders.dart';
import 'services/widget_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetSync.init();
  await SymbolCatalog.load();
  try {
    await ReminderService.instance.init();
  } catch (e) {
    debugPrint('Reminders unavailable: $e');
  }
  runApp(const ProviderScope(child: DinachariApp()));
}
