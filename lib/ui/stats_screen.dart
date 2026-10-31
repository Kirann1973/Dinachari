import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import '../domain/day.dart';
import '../domain/habit_style.dart';
import '../providers.dart';
import 'common.dart';
import 'insight_cards.dart';

/// Weekly and monthly graphs, with how each habit did in that period.
class StatsView extends ConsumerStatefulWidget {
  const StatsView({super.key});

  @override
  ConsumerState<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<StatsView> {
  bool _month = false;
  int _offset = 0; // 0 = this week/month, -1 = the one before, ...

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider).value ?? const [];
    final now = dateOnly(DateTime.now());
    final DateTime start;
    final DateTime end;
    if (_month) {
      start = DateTime(now.year, now.month + _offset);
      end = DateTime(start.year, start.month + 1, 0);
    } else {
      final ws = weekStart(now);
      start = DateTime(ws.year, ws.month, ws.day + 7 * _offset);
      end = DateTime(start.year, start.month, start.day + 6);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 4, 17, 32),
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            backgroundColor: DC.card,
            foregroundColor: DC.ink,
            selectedForegroundColor: Colors.white,
            selectedBackgroundColor: DC.accentDeep,
          ),
          segments: const [
            ButtonSegment(value: false, label: Text('Weekly')),
            ButtonSegment(value: true, label: Text('Monthly')),
          ],
          selected: {_month},
          onSelectionChanged: (s) => setState(() {
            _month = s.first;
            _offset = 0;
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: _month ? 'Previous month' : 'Previous week',
              color: Colors.white,
              onPressed: () => setState(() => _offset--),
              icon: const Icon(Icons.chevron_left),
            ),
            const Spacer(),
            if (_offset != 0)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: DC.onDark),
                onPressed: () => setState(() => _offset = 0),
                child: Text(_month ? 'This month' : 'This week'),
              ),
            const Spacer(),
            IconButton(
              tooltip: _month ? 'Next month' : 'Next week',
              color: Colors.white,
              disabledColor: Colors.white24,
              onPressed: _offset < 0 ? () => setState(() => _offset++) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (habits.isEmpty)
          const WhiteCard(child: Text('Add habits to see your graphs.'))
        else ...[
          if (_month)
            MonthChartCard(habits: habits, month: start)
          else
            WeekChartCard(habits: habits, start: start),
          const SizedBox(height: 16),
          _PerHabitCard(habits: habits, start: start, end: end),
        ],
      ],
    );
  }
}

/// Each habit's share of due days done in [start]..[end] (up to today).
class _PerHabitCard extends StatelessWidget {
  const _PerHabitCard({
    required this.habits,
    required this.start,
    required this.end,
  });

  final List<HabitWithStatus> habits;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final last = end.isAfter(today) ? today : end;
    final rows = <(HabitWithStatus, int, int)>[];
    for (final h in habits) {
      var due = 0;
      var done = 0;
      for (
        var d = start;
        !d.isAfter(last);
        d = DateTime(d.year, d.month, d.day + 1)
      ) {
        final isDone = h.doneOn(dayKey(d));
        if (h.dueOn(d) || isDone) due++;
        if (isDone) done++;
      }
      rows.add((h, done, due));
    }
    rows.sort((a, b) {
      final ra = a.$3 == 0 ? -1.0 : a.$2 / a.$3;
      final rb = b.$3 == 0 ? -1.0 : b.$2 / b.$3;
      return rb.compareTo(ra);
    });

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('By habit'),
          const SizedBox(height: 12),
          for (final (h, done, due) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  HabitIconChip(
                    iconKey: h.habit.iconKey,
                    color: Color(h.habit.color),
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DC.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: due == 0 ? 0 : done / due,
                            minHeight: 8,
                            color: Color(h.habit.color),
                            backgroundColor: tintOf(Color(h.habit.color)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    child: Text(
                      due == 0 ? '–' : '$done/$due',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: DC.display,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DC.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
