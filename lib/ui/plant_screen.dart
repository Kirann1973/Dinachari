import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../domain/plant.dart';
import '../providers.dart';
import 'common.dart';
import 'insight_cards.dart';

/// The streak plant, big, with how it grows.
class PlantView extends ConsumerWidget {
  const PlantView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).value ?? const [];
    final plant = PlantState.of(habits);
    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 4, 17, 32),
      children: [
        PlantCard(habits: habits, plantHeight: 260),
        const SizedBox(height: 16),
        WhiteCard(
          child: Row(
            children: [
              Expanded(
                child: BigStat(
                  value: '${plant.growthDays}',
                  label: 'good days in a row',
                ),
              ),
              Expanded(
                child: BigStat(
                  value: '${plant.bestGrowthDays}',
                  label: 'best run',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle('How it grows'),
              const SizedBox(height: 8),
              const Text(
                'Every day you finish at least half of the habits due that '
                'day, your plant grows a little. Days with nothing due are '
                'skipped. Miss a day and it goes back to a seed, so keep the '
                'run going.',
                style: TextStyle(fontSize: 14, color: DC.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < PlantState.levelDays.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        i <= plant.level
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: i <= plant.level
                            ? const Color(0xFF2F7D3E)
                            : DC.faint,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          PlantState.levelNames[i],
                          style: const TextStyle(fontSize: 14, color: DC.ink),
                        ),
                      ),
                      Text(
                        i == 0
                            ? 'start'
                            : '${PlantState.levelDays[i]} ${PlantState.levelDays[i] == 1 ? 'day' : 'days'}',
                        style: const TextStyle(fontSize: 13, color: DC.muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
