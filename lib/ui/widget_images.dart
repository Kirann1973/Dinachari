import 'package:flutter/material.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import 'insight_cards.dart';

/// Width the widget pictures are drawn at, in logical pixels.
const widgetImageWidth = 320.0;

/// The extra cards shown under the habits on the home-screen widget, drawn
/// to images because widgets can't run Flutter.
enum WidgetImage {
  week('img_week', 216),
  grid('img_grid', 236),
  plant('img_plant', 208);

  const WidgetImage(this.key, this.height);

  /// Prefs key holding the image file path (read by the native widget).
  final String key;
  final double height;

  Widget build(List<HabitWithStatus> habits, {bool measuring = false}) {
    final card = switch (this) {
      WidgetImage.week => WeekChartCard(
        habits: habits,
        start: weekStart(DateTime.now()),
      ),
      WidgetImage.grid => AllHabitsHeatmapCard(habits: habits),
      WidgetImage.plant => PlantCard(habits: habits, plantHeight: 110),
    };
    return MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(fontFamily: DC.body, useMaterial3: true),
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: DC.body, color: DC.ink),
            child: SizedBox(
              width: widgetImageWidth,
              height: measuring ? null : height,
              child: measuring
                  ? card
                  : Align(alignment: Alignment.topCenter, child: card),
            ),
          ),
        ),
      ),
    );
  }
}
