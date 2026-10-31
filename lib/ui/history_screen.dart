import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import '../domain/day.dart';
import '../domain/habit_style.dart';
import '../domain/plant.dart';
import '../domain/schedule.dart';
import '../providers.dart';
import 'common.dart';
import 'insight_cards.dart';

enum HistoryRange { day, week, month }

/// Past days, weeks and months: what was done, what was missed.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryRange _range = HistoryRange.day;
  DateTime _anchor = dateOnly(DateTime.now());

  void _move(int dir) {
    setState(() {
      _anchor = switch (_range) {
        HistoryRange.day => DateTime(
          _anchor.year,
          _anchor.month,
          _anchor.day + dir,
        ),
        HistoryRange.week => DateTime(
          _anchor.year,
          _anchor.month,
          _anchor.day + 7 * dir,
        ),
        HistoryRange.month => DateTime(_anchor.year, _anchor.month + dir),
      };
    });
  }

  String get _title {
    final today = dateOnly(DateTime.now());
    switch (_range) {
      case HistoryRange.day:
        if (_anchor == today) return 'Today';
        if (_anchor == daysBefore(today, 1)) return 'Yesterday';
        return DateFormat('EEE, d MMM').format(_anchor);
      case HistoryRange.week:
        final s = weekStart(_anchor);
        final e = DateTime(s.year, s.month, s.day + 6);
        return '${DateFormat('d MMM').format(s)} – ${DateFormat('d MMM').format(e)}';
      case HistoryRange.month:
        return DateFormat('MMMM y').format(_anchor);
    }
  }

  bool get _canGoForward {
    final today = dateOnly(DateTime.now());
    return switch (_range) {
      HistoryRange.day => _anchor.isBefore(today),
      HistoryRange.week => weekStart(_anchor).isBefore(weekStart(today)),
      HistoryRange.month => DateTime(
        _anchor.year,
        _anchor.month,
      ).isBefore(DateTime(today.year, today.month)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider).value ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 8, 17, 32),
      children: [
        SegmentedButton<HistoryRange>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            backgroundColor: DC.card,
            foregroundColor: DC.ink,
            selectedForegroundColor: Colors.white,
            selectedBackgroundColor: DC.accentDeep,
          ),
          segments: const [
            ButtonSegment(value: HistoryRange.day, label: Text('Day')),
            ButtonSegment(value: HistoryRange.week, label: Text('Week')),
            ButtonSegment(value: HistoryRange.month, label: Text('Month')),
          ],
          selected: {_range},
          onSelectionChanged: (s) => setState(() => _range = s.first),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              tooltip: 'Earlier',
              color: Colors.white,
              onPressed: () => _move(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: DC.display,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Later',
              color: Colors.white,
              disabledColor: Colors.white24,
              onPressed: _canGoForward ? () => _move(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          const WhiteCard(child: Text('Add habits to see your history.'))
        else
          switch (_range) {
            HistoryRange.day => _DayView(habits: habits, day: _anchor),
            HistoryRange.week => _WeekView(
              habits: habits,
              start: weekStart(_anchor),
            ),
            HistoryRange.month => _MonthView(habits: habits, month: _anchor),
          },
      ],
    );
  }
}

class _DayView extends ConsumerWidget {
  const _DayView({required this.habits, required this.day});

  final List<HabitWithStatus> habits;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = dayKey(day);
    final shown = habits.where((h) => h.dueOn(day) || h.doneOn(key)).toList();
    final repo = ref.read(habitRepositoryProvider);
    final score = dayScore(habits, day);
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            'Habits',
            trailing: score == null
                ? 'Nothing due'
                : '${shown.where((h) => h.doneOn(key)).length} of ${shown.length} done',
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            const Text(
              'No habits were due this day.',
              style: TextStyle(color: DC.muted),
            ),
          for (final h in shown)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: HabitIconChip(
                iconKey: h.habit.iconKey,
                color: Color(h.habit.color),
              ),
              title: Text(h.habit.name, style: const TextStyle(color: DC.ink)),
              subtitle: h.isCount
                  ? Text(
                      '${h.dayValues[key] ?? 0} / ${h.target} ${h.habit.unit}',
                      style: const TextStyle(color: DC.muted),
                    )
                  : null,
              trailing: Checkbox(
                value: h.doneOn(key),
                activeColor: deepOf(Color(h.habit.color)),
                onChanged: (v) => repo.setValue(
                  h.habit.id,
                  v == true ? h.target : 0,
                  day: day,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.habits, required this.start});

  final List<HabitWithStatus> habits;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    return Column(
      children: [
        WeekChartCard(habits: habits, start: start),
        const SizedBox(height: 16),
        WhiteCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      width: 30,
                      child: Text(
                        Schedule.dayLetters[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: DC.muted),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              for (final h in habits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      HabitIconChip(
                        iconKey: h.habit.iconKey,
                        color: Color(h.habit.color),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h.habit.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: DC.ink, fontSize: 14),
                        ),
                      ),
                      for (final d in days)
                        SizedBox(
                          width: 30,
                          child: Center(
                            child: _DayDot(
                              h: h,
                              day: d,
                              future: d.isAfter(today),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const _DotLegend(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.h, required this.day, required this.future});

  final HabitWithStatus h;
  final DateTime day;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final color = Color(h.habit.color);
    final key = dayKey(day);
    if (!h.dueOn(day) && !h.doneOn(key)) {
      return const Text('–', style: TextStyle(color: DC.faint));
    }
    final done = h.doneOn(key);
    final partial = !done && (h.dayValues[key] ?? 0) > 0;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? deepOf(color) : (partial ? tintOf(color) : null),
        border: Border.all(
          color: done ? deepOf(color) : (future ? DC.line : DC.faint),
          width: 2,
        ),
      ),
    );
  }
}

class _DotLegend extends StatelessWidget {
  const _DotLegend();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: DC.muted);
    return const Wrap(
      spacing: 14,
      children: [
        Text('● done', style: style),
        Text('○ missed', style: style),
        Text('– day off', style: style),
      ],
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({required this.habits, required this.month});

  final List<HabitWithStatus> habits;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;

    Color cellColor(DateTime d) {
      if (d.isAfter(today)) return Colors.transparent;
      final s = dayScore(habits, d);
      if (s == null || s <= 0) return DC.heat[0];
      if (s < 0.5) return DC.heat[1];
      if (s < 1) return DC.heat[2];
      return DC.heat[3];
    }

    return Column(
      children: [
        WhiteCard(
          child: Column(
            children: [
              Row(
                children: [
                  for (final l in Schedule.dayLetters)
                    Expanded(
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: DC.muted),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (var i = 0; i < lead; i++) const SizedBox(),
                  for (var i = 1; i <= count; i++)
                    Builder(
                      builder: (_) {
                        final d = DateTime(first.year, first.month, i);
                        final bg = cellColor(d);
                        final dark = bg == DC.heat[2] || bg == DC.heat[3];
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                            border: d == today
                                ? Border.all(color: DC.ink, width: 1.5)
                                : null,
                          ),
                          child: Text(
                            '$i',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? Colors.white
                                  : (d.isAfter(today) ? DC.faint : DC.ink),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const HeatLegend(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MonthChartCard(habits: habits, month: month),
        const SizedBox(height: 16),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardTitle('By habit'),
              const SizedBox(height: 8),
              for (final h in habits)
                _HabitMonthRow(h: h, first: first, count: count, today: today),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitMonthRow extends StatelessWidget {
  const _HabitMonthRow({
    required this.h,
    required this.first,
    required this.count,
    required this.today,
  });

  final HabitWithStatus h;
  final DateTime first;
  final int count;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    var due = 0;
    var done = 0;
    for (var i = 0; i < count; i++) {
      final d = DateTime(first.year, first.month, i + 1);
      if (d.isAfter(today)) break;
      final isDone = h.doneOn(dayKey(d));
      if (isDone) done++;
      if (h.dueOn(d) && (d != today || isDone)) due++;
    }
    final share = due == 0 ? 0.0 : (done / due).clamp(0.0, 1.0);
    final color = Color(h.habit.color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          HabitIconChip(iconKey: h.habit.iconKey, color: color, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.habit.name,
                  style: const TextStyle(color: DC.ink, fontSize: 14),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 6,
                    color: deepOf(color),
                    backgroundColor: tintOf(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$done/$due',
            style: const TextStyle(color: DC.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
