import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import '../domain/habit_style.dart';
import '../providers.dart';
import 'app_shell.dart';
import 'common.dart';
import 'habit_detail_screen.dart';
import 'habit_editor.dart';
import 'insight_cards.dart';

/// Today's habits as tiles, then this week's graph, the heatmap and the plant.
class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    return habits.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Something went wrong\n$e')),
      data: (list) {
        final due = list.where((h) => h.dueToday || h.todayValue > 0).toList();
        final rest = list.where((h) => !due.contains(h)).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(17, 4, 17, 96),
          children: [
            if (list.isEmpty)
              const _EmptyCard()
            else ...[
              _SummaryCard(habits: due),
              const SizedBox(height: 16),
              _TileGrid(habits: due),
              if (rest.isNotEmpty) ...[
                _NotDueCard(habits: rest),
                const SizedBox(height: 16),
              ],
              WeekChartCard(habits: list, start: weekStart(DateTime.now())),
              const SizedBox(height: 16),
              AllHabitsHeatmapCard(habits: list),
              const SizedBox(height: 16),
              PlantCard(
                habits: list,
                plantHeight: 120,
                onTap: () => ShellScope.of(context)?.go(Section.plant),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Habits that have a day off today.
class _NotDueCard extends StatelessWidget {
  const _NotDueCard({required this.habits});

  final List<HabitWithStatus> habits;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('Day off today'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in habits)
                ActionChip(
                  backgroundColor: DC.soft,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  avatar: HabitIconChip(
                    iconKey: h.habit.iconKey,
                    color: Color(h.habit.color),
                    size: 24,
                  ),
                  label: Text(
                    '${h.habit.name} · ${h.schedule.label}',
                    style: const TextStyle(color: DC.ink, fontSize: 13),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HabitDetailScreen(habitId: h.habit.id),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.habits});

  final List<HabitWithStatus> habits;

  @override
  Widget build(BuildContext context) {
    final done = habits.where((h) => h.doneToday).length;
    if (habits.isEmpty) {
      return const WhiteCard(
        child: CardTitle('Today', trailing: 'Nothing due, enjoy the day off'),
      );
    }
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle('Today', trailing: '$done of ${habits.length} done'),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < habits.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: habits[i].doneToday
                          ? Color(habits[i].habit.color)
                          : DC.soft,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.habits});

  final List<HabitWithStatus> habits;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < habits.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: HabitTile(item: habits[i])),
                const SizedBox(width: 16),
                Expanded(
                  child: i + 1 < habits.length
                      ? HabitTile(item: habits[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// One habit as a square-ish tile, like the mockup's small widgets.
class HabitTile extends ConsumerWidget {
  const HabitTile({super.key, required this.item});

  final HabitWithStatus item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = item.habit;
    final color = Color(habit.color);
    final repo = ref.read(habitRepositoryProvider);

    return WhiteCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DC.muted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              HabitIconChip(iconKey: habit.iconKey, color: color, size: 30),
            ],
          ),
          const SizedBox(height: 14),
          if (item.isCount) ...[
            BigStat(
              value: '${item.todayValue}',
              label: '${item.streaks.current} day streak',
              color: deepOf(color),
              trailing:
                  '/ ${item.target}'
                  '${habit.unit.isEmpty ? '' : ' ${habit.unit}'}',
            ),
            const SizedBox(height: 10),
            _Dots(value: item.todayValue, target: item.target, color: color),
          ] else
            BigStat(value: '${item.streaks.current}', label: 'day streak'),
          const SizedBox(height: 14),
          if (item.isCount)
            _PillButton(
              label: item.doneToday ? 'Goal reached · +1' : '+1',
              background: deepOf(color),
              foreground: Colors.white,
              semantics: 'Add one to ${habit.name}',
              onPressed: () => repo.addToToday(habit.id, 1),
              onLongPress: () => repo.addToToday(habit.id, -1),
            )
          else
            _PillButton(
              label: item.doneToday ? 'Done today' : 'Mark done',
              background: item.doneToday ? deepOf(color) : tintOf(color),
              foreground: item.doneToday ? Colors.white : deepOf(color),
              semantics: item.doneToday
                  ? '${habit.name} done today. Tap to undo'
                  : 'Mark ${habit.name} done',
              icon: item.doneToday ? Icons.check : null,
              onPressed: () => repo.toggleToday(habit.id),
            ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.value, required this.target, required this.color});

  final int value;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (target > 12) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: (value / target).clamp(0, 1),
          minHeight: 6,
          color: color,
          backgroundColor: tintOf(color),
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < target; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i < value ? color : tintOf(color),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    required this.semantics,
    this.onLongPress,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final String semantics;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          onLongPress: onLongPress,
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('Start your daily routine'),
          const SizedBox(height: 8),
          const Text(
            'Add habits like Gym, Bath or Drink water. Pick an icon and a '
            'color for each, then tick them off here or from your home screen.',
            style: TextStyle(fontSize: 14, color: DC.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: DC.accentDeep,
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: () => openHabitEditor(context),
            icon: const Icon(Icons.add),
            label: const Text('Add your first habit'),
          ),
        ],
      ),
    );
  }
}
