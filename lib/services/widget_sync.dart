import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../data/habit_repository.dart';

/// Pushes today's habit summary to the home-screen widgets.
///
/// The native widgets (Jetpack Glance on Android, WidgetKit on iOS/macOS)
/// read the `today_json` key. Windows uses a tray app instead and is skipped.
class WidgetSync {
  static const appGroupId = 'group.com.kiran.dinachari';
  static const androidWidget = 'DinachariWidgetReceiver';
  static const iosWidget = 'DinachariWidget';
  static const dataKey = 'today_json';

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Builds the JSON payload the native widgets render.
  static String buildPayload(List<HabitWithStatus> habits) {
    final done = habits.where((h) => h.doneToday).length;
    return jsonEncode({
      'done': done,
      'total': habits.length,
      'habits': [
        for (final h in habits)
          {
            'id': h.habit.id,
            'name': h.habit.name,
            'emoji': h.habit.emoji,
            'done': h.doneToday,
            'streak': h.streaks.current,
          },
      ],
    });
  }

  static Future<void> push(List<HabitWithStatus> habits) async {
    if (!_supported) return;
    try {
      await HomeWidget.saveWidgetData<String>(dataKey, buildPayload(habits));
      await HomeWidget.updateWidget(
        androidName: androidWidget,
        iOSName: iosWidget,
      );
    } catch (e) {
      // Native widget not added yet; the app keeps working without it.
      debugPrint('Widget sync skipped: $e');
    }
  }
}
