import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import '../domain/day.dart';
import '../domain/plant.dart';
import 'charts.dart';
import 'common.dart';

/// Monday of the week containing [day].
DateTime weekStart(DateTime day) => daysBefore(dateOnly(day), day.weekday - 1);

/// Bars for each day of the week starting [start]: share of habits done.
class WeekChartCard extends StatelessWidget {
  const WeekChartCard({super.key, required this.habits, required this.start});

  final List<HabitWithStatus> habits;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    final values = [
      for (final d in days) d.isAfter(today) ? null : dayScore(habits, d),
    ];
    final past = values.whereType<double>().toList();
    final avg = past.isEmpty ? 0 : past.reduce((a, b) => a + b) / past.length;
    final end = days.last;
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            weekStart(today) == start
                ? 'This week'
                : '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM').format(end)}',
            trailing: '${(avg * 100).round()}% done',
          ),
          const SizedBox(height: 14),
          BarChart(
            values: values,
            labels: [
              for (final d in days) DateFormat('E').format(d).substring(0, 1),
            ],
            highlight: days.contains(today) ? days.indexOf(today) : null,
            semanticsLabel: 'Share of habits done each day this week',
          ),
        ],
      ),
    );
  }
}

/// Bars for each day of a month: share of habits done.
class MonthChartCard extends StatelessWidget {
  const MonthChartCard({super.key, required this.habits, required this.month});

  final List<HabitWithStatus> habits;

  /// Any day in the month.
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final days = [
      for (var i = 0; i < count; i++) DateTime(first.year, first.month, i + 1),
    ];
    final values = [
      for (final d in days) d.isAfter(today) ? null : dayScore(habits, d),
    ];
    final past = values.whereType<double>().toList();
    final avg = past.isEmpty ? 0 : past.reduce((a, b) => a + b) / past.length;
    final perfect = past.where((v) => v >= 1).length;
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            DateFormat('MMMM y').format(first),
            trailing: '${(avg * 100).round()}% done',
          ),
          const SizedBox(height: 14),
          BarChart(
            values: values,
            labels: [for (final d in days) '${d.day}'],
            highlight: days.contains(today) ? days.indexOf(today) : null,
            semanticsLabel: 'Share of habits done each day this month',
          ),
          const SizedBox(height: 8),
          Text(
            '$perfect perfect ${perfect == 1 ? 'day' : 'days'} (everything done)',
            style: const TextStyle(fontSize: 13, color: DC.muted),
          ),
        ],
      ),
    );
  }
}

/// Heatmap of all habits for the last 15 weeks.
class AllHabitsHeatmapCard extends StatelessWidget {
  const AllHabitsHeatmapCard({super.key, required this.habits});

  final List<HabitWithStatus> habits;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final scores = <double>[];
    for (var i = 0; i < 30; i++) {
      final s = dayScore(habits, daysBefore(today, i));
      // Today only counts once something is done.
      if (s != null && (i > 0 || s > 0)) scores.add(s);
    }
    final consistency = scores.isEmpty
        ? 0
        : (scores.reduce((a, b) => a + b) / scores.length * 100).round();

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle('Last 15 weeks', trailing: '$consistency% consistency'),
          const SizedBox(height: 12),
          Heatmap(
            colorFor: (day) {
              final s = dayScore(habits, parseDayKey(day));
              if (s == null || s <= 0) return DC.heat[0];
              if (s < 0.5) return DC.heat[1];
              if (s < 1) return DC.heat[2];
              return DC.heat[3];
            },
          ),
          const SizedBox(height: 8),
          const HeatLegend(),
        ],
      ),
    );
  }
}

/// The streak plant with its level and progress to the next level.
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.habits,
    this.name = 'Sprout',
    this.onTap,
    this.plantHeight = 150,
  });

  final List<HabitWithStatus> habits;
  final String name;
  final VoidCallback? onTap;
  final double plantHeight;

  static const _green = Color(0xFF1F4D2B);

  @override
  Widget build(BuildContext context) {
    final plant = PlantState.of(habits);
    return WhiteCard(
      color: const Color(0xFFECF5EC),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your plant, $name',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ),
              Text(
                'Level ${plant.level} · ${plant.levelName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ],
          ),
          Semantics(
            label: '$name, ${plant.levelName}',
            child: SizedBox(
              height: plantHeight,
              child: CustomPaint(painter: PlantPainter(plant.level)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plant.isMaxLevel
                ? 'In full bloom! Keep going to keep it that way.'
                : '${plant.daysToNext} more good ${plant.daysToNext == 1 ? 'day' : 'days'} to grow into a ${plant.nextName.toLowerCase()}',
            style: const TextStyle(fontSize: 13, color: _green),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: plant.progress,
              minHeight: 8,
              color: const Color(0xFF2F7D3E),
              backgroundColor: const Color(0xFFCFE3D0),
            ),
          ),
        ],
      ),
    );
  }
}
