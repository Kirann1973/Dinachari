import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/widget_actions.dart';
import 'services/widget_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetSync.init();
  await WidgetSync.registerInteraction(widgetInteraction);
  runApp(const ProviderScope(child: DinachariApp()));
}
