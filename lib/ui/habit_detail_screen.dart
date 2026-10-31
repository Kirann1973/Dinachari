import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import '../domain/day.dart';
import '../domain/habit_style.dart';
import '../providers.dart';
import 'common.dart';
import 'habit_editor.dart';

/// Streaks, today's progress and 15 weeks of history for one habit.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).value ?? const [];
    final matches = habits.where((h) => h.habit.id == habitId);
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Habit not found')));
    }
    final item = matches.first;
    final habit = item.habit;
    final color = Color(habit.color);
    final repo = ref.read(habitRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Edit habit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => openHabitEditor(context, existing: habit),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              if (value == 'archive') {
                await repo.archiveHabit(habitId);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${habit.name} archived. Find it under Archived in the menu.',
                    ),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => repo.restoreHabit(habitId),
                    ),
                  ),
                );
              }
              if (value == 'delete') {
                if (!context.mounted) return;
                final ok = await _confirmDelete(context, habit.name);
                if (!ok) return;
                await repo.deleteHabit(habitId);
              }
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
        padding: const EdgeInsets.fromLTRB(17, 0, 17, 32),
        children: [
          Row(
            children: [
              HabitIconChip(
                iconKey: habit.iconKey,
                color: color,
                size: 48,
                filled: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  habit.name,
                  style: const TextStyle(
                    fontFamily: DC.display,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WhiteCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BigStat(
                        value: '${item.streaks.current}',
                        label: 'day streak',
                        size: 56,
                      ),
                    ),
                    Flame(color: deepOf(color), size: 32),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: BigStat(
                        value: '${item.streaks.best}',
                        label: 'best streak',
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: BigStat(
                        value: '${item.completedDays.length}',
                        label: 'days done',
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: BigStat(
                        value: '${(item.consistency() * 100).round()}%',
                        label: 'last 30 days',
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TodayCard(item: item, repo: repo),
          const SizedBox(height: 16),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle(
                  'Last 15 weeks',
                  trailing: 'Tap a day to fix it',
                ),
                const SizedBox(height: 12),
                Heatmap(
                  colorFor: (day) => habitHeatColor(item, day),
                  onTapDay: (day) {
                    final done =
                        (item.dayValues[dayKey(day)] ?? 0) >= item.target;
                    repo.setValue(habit.id, done ? 0 : item.target, day: day);
                  },
                ),
                const SizedBox(height: 8),
                HeatLegend(shades: shadesFor(color).sublist(0, 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text('This removes the habit and all its history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.item, required this.repo});

  final HabitWithStatus item;
  final HabitRepository repo;

  @override
  Widget build(BuildContext context) {
    final habit = item.habit;
    final color = Color(habit.color);

    if (!item.isCount) {
      return WhiteCard(
        child: Row(
          children: [
            Expanded(
              child: CardTitle(
                'Today',
                trailing: item.doneToday ? 'Done' : 'Not yet',
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: item.doneToday ? deepOf(color) : tintOf(color),
                foregroundColor: item.doneToday ? Colors.white : deepOf(color),
                minimumSize: const Size(140, 44),
              ),
              onPressed: () => repo.toggleToday(habit.id),
              icon: Icon(item.doneToday ? Icons.check : Icons.circle_outlined),
              label: Text(item.doneToday ? 'Done today' : 'Mark done'),
            ),
          ],
        ),
      );
    }

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            'Today',
            trailing: item.doneToday ? 'Goal reached' : 'Goal ${item.target}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filled(
                tooltip: 'Remove one',
                style: IconButton.styleFrom(
                  backgroundColor: tintOf(color),
                  foregroundColor: deepOf(color),
                  disabledBackgroundColor: DC.soft,
                ),
                onPressed: item.todayValue > 0
                    ? () => repo.addToToday(habit.id, -1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: BigStat(
                    value: '${item.todayValue}',
                    label: habit.unit.isEmpty ? 'today' : habit.unit,
                    color: deepOf(color),
                    trailing: '/ ${item.target}',
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Add one',
                style: IconButton.styleFrom(backgroundColor: deepOf(color)),
                onPressed: () => repo.addToToday(habit.id, 1),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
