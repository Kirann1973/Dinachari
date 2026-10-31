import 'package:flutter/material.dart';

import '../app.dart';
import '../data/habit_repository.dart';
import '../domain/day.dart';
import 'habit_look_view.dart';

/// The white rounded card used everywhere.
class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = DC.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A habit's look (emoji, icon, photo or text) in a tinted circle.
class HabitIconChip extends StatelessWidget {
  const HabitIconChip({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 36,
    this.filled = false,
  });

  final String iconKey;
  final Color color;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) =>
      HabitLookView(look: iconKey, color: color, size: size, filled: filled);
}

/// Big Space Grotesk number with a small caption under it.
class BigStat extends StatelessWidget {
  const BigStat({
    super.key,
    required this.value,
    required this.label,
    this.size = 44,
    this.color = DC.ink,
    this.trailing,
  });

  final String value;
  final String label;
  final double size;
  final Color color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: DC.display,
                fontSize: size,
                fontWeight: FontWeight.w700,
                height: 1,
                color: color,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  trailing!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: DC.muted),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: DC.muted)),
      ],
    );
  }
}

/// Flame icon used next to streaks.
class Flame extends StatelessWidget {
  const Flame({super.key, this.color = DC.accentDeep, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.local_fire_department_outlined, color: color, size: size);
}

/// Heatmap of the last [weeks] weeks, one square per day, Monday on top.
class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.colorFor,
    this.weeks = 15,
    this.onTapDay,
  });

  /// Square color for a given day.
  final Color Function(String dayKey) colorFor;
  final int weeks;
  final void Function(DateTime day)? onTapDay;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final thisMonday = daysBefore(today, today.weekday - 1);
    final start = daysBefore(thisMonday, (weeks - 1) * 7);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final size = ((constraints.maxWidth - gap * (weeks - 1)) / weeks).clamp(
          6.0,
          22.0,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var w = 0; w < weeks; w++)
              Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    _cell(
                      DateTime(start.year, start.month, start.day + w * 7 + d),
                      today,
                      size,
                      gap,
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _cell(DateTime day, DateTime today, double size, double gap) {
    final future = day.isAfter(today);
    final box = Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(bottom: gap),
      decoration: BoxDecoration(
        color: future ? Colors.transparent : colorFor(dayKey(day)),
        borderRadius: BorderRadius.circular(4),
        border: day == today ? Border.all(color: DC.ink, width: 1.5) : null,
      ),
    );
    if (future || onTapDay == null) return box;
    return GestureDetector(onTap: () => onTapDay!(day), child: box);
  }
}

/// Less → More legend for heatmaps.
class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key, this.shades = DC.heat});

  final List<Color> shades;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Less', style: TextStyle(fontSize: 12, color: DC.muted)),
        const SizedBox(width: 6),
        for (final c in shades)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const Text('More', style: TextStyle(fontSize: 12, color: DC.muted)),
      ],
    );
  }
}

/// Four heat shades for one habit color.
List<Color> shadesFor(Color c) => [
  DC.soft,
  Color.lerp(Colors.white, c, 0.45)!,
  c,
  deepOf(c),
];

/// Heat color for a habit on a day: none, partial (counted habits), done.
Color habitHeatColor(HabitWithStatus h, String day) {
  final shades = shadesFor(Color(h.habit.color));
  final v = h.dayValues[day] ?? 0;
  if (v <= 0) return shades[0];
  if (v >= h.target) return shades[2];
  return shades[1];
}

/// Section title in a white card.
class CardTitle extends StatelessWidget {
  const CardTitle(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: DC.display,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: DC.ink,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(fontSize: 13, color: DC.muted),
          ),
      ],
    );
  }
}
