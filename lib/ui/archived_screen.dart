import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../providers.dart';
import 'common.dart';

/// Habits you archived, with buttons to bring them back or delete them.
class ArchivedView extends ConsumerWidget {
  const ArchivedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = ref.watch(archivedHabitsProvider).value ?? const [];
    final repo = ref.read(habitRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 4, 17, 32),
      children: [
        if (archived.isEmpty)
          const WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle('Nothing archived'),
                SizedBox(height: 8),
                Text(
                  'When you archive a habit it moves here. Its history is kept, '
                  'and you can bring it back any time.',
                  style: TextStyle(fontSize: 14, color: DC.muted, height: 1.4),
                ),
              ],
            ),
          ),
        for (final h in archived)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WhiteCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  HabitIconChip(
                    iconKey: h.habit.iconKey,
                    color: Color(h.habit.color),
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.habit.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DC.ink,
                          ),
                        ),
                        Text(
                          '${h.completedDays.length} days done · best streak ${h.streaks.best}',
                          style: const TextStyle(fontSize: 13, color: DC.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: DC.accentDeep),
                    onPressed: () async {
                      await repo.restoreHabit(h.habit.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${h.habit.name} is back on Today'),
                        ),
                      );
                    },
                    child: const Text('Restore'),
                  ),
                  IconButton(
                    tooltip: 'Delete ${h.habit.name}',
                    color: DC.muted,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Delete ${h.habit.name}?'),
                          content: const Text(
                            'This removes the habit and all of its history. '
                            'It can\'t be undone.',
                          ),
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
                      if (ok == true) await repo.deleteHabit(h.habit.id);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
