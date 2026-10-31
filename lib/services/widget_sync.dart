import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../data/habit_repository.dart';
import '../domain/day.dart';
import '../domain/habit_style.dart';

/// Keeps the home-screen widgets and the app in step.
///
/// The app writes today's habits as JSON under [dataKey]. Taps on the Android
/// widget are handled natively (instant, works with the app closed): the
/// widget updates that JSON itself and queues each change under [pendingKey].
/// The app applies the queue to the database when it starts or comes back.
class WidgetSync {
  static const appGroupId = 'group.com.kiran.dinachari';
  static const androidWidget =
      'com.kiran.dinachari.widget.DinachariWidgetReceiver';
  static const iosWidget = 'DinachariWidget';
  static const dataKey = 'today_json';
  static const pendingKey = 'pending_json';

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static final Set<String> _renderedIcons = {};

  static Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Prefs key under which the PNG for this icon + color is stored.
  static String iconImageKey(String iconKey, int color) =>
      'icon_${iconKey}_${color.toRadixString(16)}';

  /// Builds the JSON payload the native widgets render.
  static String buildPayload(List<HabitWithStatus> habits, {DateTime? now}) {
    return jsonEncode({
      'day': dayKey(now ?? DateTime.now()),
      'habits': [
        for (final h in habits)
          {
            'id': h.habit.id,
            'name': h.habit.name,
            'icon': iconImageKey(h.habit.iconKey, h.habit.color),
            'color': h.habit.color,
            'kind': h.isCount ? 'count' : 'check',
            'target': h.target,
            'unit': h.habit.unit,
            'value': h.todayValue,
            'streakBefore': h.streakBeforeToday,
          },
      ],
    });
  }

  /// Draws each habit's icon to a small PNG the native widget can show.
  static Future<void> _renderIcons(List<HabitWithStatus> habits) async {
    for (final h in habits) {
      final key = iconImageKey(h.habit.iconKey, h.habit.color);
      if (_renderedIcons.contains(key)) continue;
      final existing = await HomeWidget.getWidgetData<String>(key);
      if (existing == null) {
        await HomeWidget.renderFlutterWidget(
          Icon(
            habitIcon(h.habit.iconKey),
            color: Color(h.habit.color),
            size: 40,
          ),
          key: key,
          logicalSize: const Size(40, 40),
          pixelRatio: 3,
        );
      }
      _renderedIcons.add(key);
    }
  }

  static Future<void> push(List<HabitWithStatus> habits) async {
    if (!_supported) return;
    try {
      await _renderIcons(habits);
      await HomeWidget.saveWidgetData<String>(dataKey, buildPayload(habits));
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidWidget,
        iOSName: iosWidget,
      );
    } catch (e) {
      debugPrint('Widget sync skipped: $e');
    }
  }

  /// Parses queued widget changes: a list of `{id, day, value}`.
  static List<({int id, String day, int value})> parsePending(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return [
        for (final e in list.cast<Map<String, dynamic>>())
          (
            id: (e['id'] as num).toInt(),
            day: e['day'] as String,
            value: (e['value'] as num).toInt(),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Applies taps made on the widget to the database. Safe to call often.
  static Future<void> applyPending(HabitRepository repo) async {
    if (!_supported) return;
    try {
      final first = parsePending(
        await HomeWidget.getWidgetData<String>(pendingKey),
      );
      if (first.isEmpty) return;
      for (final p in first) {
        await repo.setValueForKey(p.id, p.value, p.day);
      }
      // Keep anything the widget queued while we were applying.
      final now = parsePending(
        await HomeWidget.getWidgetData<String>(pendingKey),
      );
      final rest = now.length > first.length
          ? now.sublist(first.length)
          : const <({int id, String day, int value})>[];
      await HomeWidget.saveWidgetData<String>(
        pendingKey,
        rest.isEmpty
            ? null
            : jsonEncode([
                for (final p in rest)
                  {'id': p.id, 'day': p.day, 'value': p.value},
              ]),
      );
    } catch (e) {
      debugPrint('Applying widget taps failed: $e');
    }
  }
}
