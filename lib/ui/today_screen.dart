import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import '../providers.dart';
import 'habit_detail_screen.dart';
import 'habit_editor.dart';

/// Home screen: today's habits, tap a card to check it off.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-read when coming back, so "today" rolls over after midnight.
    if (state == AppLifecycleState.resumed) ref.invalidate(habitsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dinachari',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add habit',
        onPressed: () => showHabitEditor(context),
        child: const Icon(Icons.add),
      ),
      body: habits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong\n$e')),
        data: (list) => list.isEmpty
            ? const _EmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _ProgressHeader(habits: list),
                  const SizedBox(height: 12),
                  for (final h in list) ...[
                    _HabitCard(item: h),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.habits});

  final List<HabitWithStatus> habits;

  @override
  Widget build(BuildContext context) {
    final done = habits.where((h) => h.doneToday).length;
    final total = habits.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DinachariColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today',
                    style: TextStyle(color: DinachariColors.mutedOnCard)),
                const SizedBox(height: 4),
                Text(
                  '$done of $total done',
                  style: const TextStyle(
                    color: DinachariColors.textOnCard,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : done / total,
              strokeWidth: 6,
              backgroundColor: const Color(0xFFEDEDED),
              color: DinachariColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  const _HabitCard({required this.item});

  final HabitWithStatus item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = item.habit;
    return Material(
      color: DinachariColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            ref.read(habitRepositoryProvider).toggleToday(habit.id),
        onLongPress: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HabitDetailScreen(habitId: habit.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        color: DinachariColors.textOnCard,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.streaks.current == 0
                          ? 'Start a streak today'
                          : '🔥 ${item.streaks.current} day streak',
                      style: const TextStyle(
                        color: DinachariColors.mutedOnCard,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _CheckCircle(done: item.doneToday),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? DinachariColors.accent : Colors.transparent,
        border: Border.all(
          color: done ? DinachariColors.accent : const Color(0xFFD0D0D0),
          width: 2,
        ),
      ),
      child: done
          ? const Icon(Icons.check, size: 20, color: Colors.white)
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No habits yet.\nTap + to add your first one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
