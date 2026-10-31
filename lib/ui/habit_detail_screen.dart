import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import '../domain/day.dart';
import '../providers.dart';
import 'habit_editor.dart';

/// Streaks and the last 12 weeks of history for one habit.
/// Tap a past day to fix a missed check-in.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  static const _weeks = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).value ?? const [];
    final matches = habits.where((h) => h.habit.id == habitId);
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Habit not found')));
    }
    final item = matches.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('${item.habit.emoji}  ${item.habit.name}'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showHabitEditor(context, existing: item.habit),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final repo = ref.read(habitRepositoryProvider);
              final nav = Navigator.of(context);
              if (value == 'archive') await repo.archiveHabit(habitId);
              if (value == 'delete') await repo.deleteHabit(habitId);
              nav.pop();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'archive', child: Text('Archive')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Current streak',
                  value: '${item.streaks.current}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Best streak',
                  value: '${item.streaks.best}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total days',
                  value: '${item.completedDays.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Last $_weeks weeks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _HistoryGrid(item: item, weeks: _weeks),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DinachariColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: DinachariColors.accent,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: DinachariColors.mutedOnCard,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// A week-per-column grid, oldest on the left, ending with this week.
class _HistoryGrid extends ConsumerWidget {
  const _HistoryGrid({required this.item, required this.weeks});

  final HabitWithStatus item;
  final int weeks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateOnly(DateTime.now());
    // Monday of the current week.
    final thisMonday = daysBefore(today, today.weekday - 1);
    final start = daysBefore(thisMonday, (weeks - 1) * 7);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final size = ((constraints.maxWidth - gap * (weeks - 1)) / weeks).clamp(
          8.0,
          28.0,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var w = 0; w < weeks; w++)
              Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: gap),
                      child: _DayCell(
                        day: DateTime(
                          start.year,
                          start.month,
                          start.day + w * 7 + d,
                        ),
                        today: today,
                        size: size,
                        done: item.completedDays.contains(
                          dayKey(
                            DateTime(
                              start.year,
                              start.month,
                              start.day + w * 7 + d,
                            ),
                          ),
                        ),
                        onTap: (day, done) => ref
                            .read(habitRepositoryProvider)
                            .setDone(item.habit.id, !done, day: day),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.size,
    required this.done,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final double size;
  final bool done;
  final void Function(DateTime day, bool done) onTap;

  @override
  Widget build(BuildContext context) {
    final future = day.isAfter(today);
    return GestureDetector(
      onTap: future ? null : () => onTap(day, done),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: future
              ? Colors.transparent
              : done
              ? DinachariColors.accent
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(4),
          border: day == today
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
        ),
      ),
    );
  }
}
