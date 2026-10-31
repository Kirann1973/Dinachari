import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';
import '../data/habit_repository.dart';
import '../domain/habit_look.dart';
import '../domain/reminder_plan.dart';
import '../domain/schedule.dart';

/// Schedules habit reminders as local notifications.
///
/// Rather than repeating alarms, it books the next two weeks of one-off
/// notifications and rebuilds them whenever habits change, so a habit that's
/// already done today doesn't nag, and days off are skipped.
class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Timer? _debounce;

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  Future<void> init() async {
    if (!supported || _ready) return;
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      // Unknown zone: fall back to UTC offsets from DateTime.
    }
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
    );
    _ready = true;
  }

  /// Asks for permission to show notifications (and exact timing on
  /// Android). Returns false if the user said no.
  Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ok = await android?.requestNotificationsPermission() ?? true;
      if (ok && !(await android?.canScheduleExactNotifications() ?? true)) {
        await android?.requestExactAlarmsPermission();
      }
      return ok;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  /// Rebuilds all scheduled reminders (debounced).
  void reschedule(List<HabitWithStatus> habits, List<(Habit, Reminder)> all) {
    if (!supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _reschedule(habits, all).catchError((Object e) {
        debugPrint('Scheduling reminders failed: $e');
      });
    });
  }

  Future<void> _reschedule(
    List<HabitWithStatus> habits,
    List<(Habit, Reminder)> all,
  ) async {
    await init();
    await _plugin.cancelAll();
    if (all.isEmpty) return;

    final byId = {for (final h in habits) h.habit.id: h};
    final rules = <int, List<ReminderRule>>{};
    for (final (habit, r) in all) {
      rules
          .putIfAbsent(habit.id, () => [])
          .add(
            ReminderRule(
              minute: r.minute,
              every: r.every,
              endMinute: r.endMinute,
            ),
          );
    }
    final plan = planReminders(
      habits: [
        for (final e in rules.entries)
          if (byId[e.key] case final h?)
            (
              habitId: h.habit.id,
              schedule: Schedule(h.habit.days),
              doneToday: h.doneToday,
              rules: e.value,
            ),
      ],
      now: DateTime.now(),
    );

    final android = await _canExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (var i = 0; i < plan.length; i++) {
      final p = plan[i];
      final h = byId[p.habitId]!;
      await _plugin.zonedSchedule(
        id: i,
        scheduledDate: tz.TZDateTime.from(p.at, tz.local),
        notificationDetails: details(h.habit.sound),
        androidScheduleMode: android,
        title: _title(h.habit),
        body: h.isCount
            ? 'Goal today: ${h.target}${h.habit.unit.isEmpty ? '' : ' ${h.habit.unit}'}'
            : 'Time for ${h.habit.name}. Tap to open Dinachari.',
        payload: '${h.habit.id}',
      );
    }
  }

  Future<bool> _canExact() async {
    if (!Platform.isAndroid) return true;
    return await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.canScheduleExactNotifications() ??
        false;
  }

  String _title(Habit habit) => switch (HabitLook.parse(habit.iconKey)) {
    EmojiLook(:final emoji) => '$emoji ${habit.name}',
    _ => habit.name,
  };

  /// Notification look and sound for a habit's [sound] setting.
  ///
  /// Android fixes a sound per channel, so each sound gets its own channel.
  static NotificationDetails details(String sound) {
    final silent = sound == 'silent';
    final AndroidNotificationSound? androidSound;
    if (sound.startsWith('raw:')) {
      androidSound = RawResourceAndroidNotificationSound(sound.substring(4));
    } else if (sound.startsWith('uri:')) {
      final bar = sound.lastIndexOf('|');
      androidSound = UriAndroidNotificationSound(
        sound.substring(4, bar > 0 ? bar : sound.length),
      );
    } else {
      androidSound = null;
    }
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders_${_channelKey(sound)}',
        'Reminders · ${soundLabel(sound)}',
        channelDescription: 'Habit reminders that play ${soundLabel(sound)}',
        importance: silent ? Importance.low : Importance.high,
        priority: silent ? Priority.low : Priority.high,
        playSound: !silent,
        sound: androidSound,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(presentSound: !silent),
      macOS: DarwinNotificationDetails(presentSound: !silent),
    );
  }

  static String _channelKey(String sound) {
    var h = 0x811c9dc5;
    for (final c in sound.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  /// Shows a reminder right now, to try a sound.
  Future<void> preview(Habit habit) async {
    if (!supported) return;
    await init();
    await _plugin.show(
      id: 9999,
      title: _title(habit),
      body: 'This is how reminders for ${habit.name} will sound.',
      notificationDetails: details(habit.sound),
    );
  }
}

/// Sounds on the phone (Android): opens the system sound picker and plays
/// previews. Implemented in MainActivity.kt.
class PhoneSounds {
  static const _channel = MethodChannel('dinachari/sounds');

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Returns `uri:<uri>|<title>`, or null if the user cancelled.
  static Future<String?> pick({String? current}) async {
    if (!supported) return null;
    final result = await _channel.invokeMapMethod<String, String>('pick', {
      'current': current,
    });
    if (result == null) return null;
    return 'uri:${result['uri']}|${result['title'] ?? 'Phone sound'}';
  }

  /// Plays a stored sound value once.
  static Future<void> play(String sound) async {
    if (!supported || sound == 'silent') return;
    await _channel.invokeMethod('play', {'sound': sound});
  }
}
