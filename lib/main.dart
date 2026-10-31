import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'domain/symbols.dart';
import 'services/widget_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetSync.init();
  await SymbolCatalog.load();
  runApp(const ProviderScope(child: DinachariApp()));
}
