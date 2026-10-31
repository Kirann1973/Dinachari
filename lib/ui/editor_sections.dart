import 'package:flutter/material.dart';

import '../app.dart';
import '../domain/reminder_plan.dart';
import '../domain/schedule.dart';
import '../services/reminders.dart';

/// Section heading inside an editor card.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DC.ink,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

ButtonStyle _chipStyle(bool selected) => OutlinedButton.styleFrom(
  backgroundColor: selected ? DC.accentDeep : DC.card,
  foregroundColor: selected ? Colors.white : DC.ink,
  side: BorderSide(color: selected ? DC.accentDeep : DC.line),
  minimumSize: const Size(0, 40),
  padding: const EdgeInsets.symmetric(horizontal: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
);

/// Every day / Weekdays / Weekends / Custom, with day toggles for custom.
class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({
    super.key,
    required this.mask,
    required this.onChanged,
  });

  final int mask;
  final ValueChanged<int> onChanged;

  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  late bool _custom = ![
    Schedule.everyDay.mask,
    Schedule.weekdays.mask,
    Schedule.weekends.mask,
  ].contains(widget.mask);

  @override
  Widget build(BuildContext context) {
    final mask = widget.mask;
    Widget preset(String label, Schedule s) {
      final selected = !_custom && mask == s.mask;
      return OutlinedButton(
        style: _chipStyle(selected),
        onPressed: () {
          setState(() => _custom = false);
          widget.onChanged(s.mask);
        },
        child: Text(label),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            preset('Every day', Schedule.everyDay),
            preset('Weekdays', Schedule.weekdays),
            preset('Weekends', Schedule.weekends),
            OutlinedButton(
              style: _chipStyle(_custom),
              onPressed: () => setState(() => _custom = true),
              child: const Text('Custom'),
            ),
          ],
        ),
        if (_custom) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var wd = 1; wd <= 7; wd++)
                _DayToggle(
                  label: Schedule.dayLetters[wd - 1],
                  name: Schedule.dayNames[wd - 1],
                  selected: Schedule(mask).hasWeekday(wd),
                  onTap: () => widget.onChanged(Schedule(mask).toggle(wd).mask),
                ),
            ],
          ),
          if (mask == 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Pick at least one day.',
                style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? DC.accentDeep : DC.soft,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : DC.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// List of reminders with buttons to add a time or a repeating reminder.
class RemindersEditor extends StatelessWidget {
  const RemindersEditor({
    super.key,
    required this.rules,
    required this.onChanged,
  });

  final List<ReminderRule> rules;
  final ValueChanged<List<ReminderRule>> onChanged;

  Future<int?> _pickTime(BuildContext context, int initial, String help) async {
    final t = await showTimePicker(
      context: context,
      helpText: help,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Future<void> _addTime(BuildContext context) async {
    final m = await _pickTime(context, 8 * 60, 'Remind me at');
    if (m == null) return;
    onChanged([...rules, ReminderRule(minute: m)]..sort(_byMinute));
  }

  Future<void> _addRepeating(BuildContext context) async {
    final rule = await showDialog<ReminderRule>(
      context: context,
      builder: (_) => const _RepeatingDialog(),
    );
    if (rule == null) return;
    onChanged([...rules, rule]..sort(_byMinute));
  }

  static int _byMinute(ReminderRule a, ReminderRule b) =>
      a.minute.compareTo(b.minute);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rules.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'No reminders yet.',
              style: TextStyle(color: DC.muted, fontSize: 13),
            ),
          ),
        for (var i = 0; i < rules.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: DC.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  rules[i].repeats ? Icons.repeat : Icons.alarm,
                  size: 20,
                  color: DC.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rules[i].label,
                    style: const TextStyle(color: DC.ink, fontSize: 15),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove reminder',
                  icon: const Icon(Icons.close, color: DC.muted),
                  onPressed: () => onChanged([...rules]..removeAt(i)),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              style: _chipStyle(false),
              onPressed: () => _addTime(context),
              icon: const Icon(Icons.alarm_add, size: 18),
              label: const Text('At a time'),
            ),
            OutlinedButton.icon(
              style: _chipStyle(false),
              onPressed: () => _addRepeating(context),
              icon: const Icon(Icons.repeat, size: 18),
              label: const Text('Every few hours'),
            ),
          ],
        ),
        if (!ReminderService.supported)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Reminders show on Android, iPhone and Mac.',
              style: TextStyle(color: DC.muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _RepeatingDialog extends StatefulWidget {
  const _RepeatingDialog();

  @override
  State<_RepeatingDialog> createState() => _RepeatingDialogState();
}

class _RepeatingDialogState extends State<_RepeatingDialog> {
  int _every = 120;
  int _start = 8 * 60;
  int _end = 20 * 60;

  static const _steps = [15, 30, 45, 60, 90, 120, 180, 240];

  Future<void> _pick(bool start) async {
    final initial = start ? _start : _end;
    final t = await showTimePicker(
      context: context,
      helpText: start ? 'From' : 'Until',
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (t == null) return;
    setState(() {
      if (start) {
        _start = t.hour * 60 + t.minute;
      } else {
        _end = t.hour * 60 + t.minute;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final valid = _end > _start;
    final rule = ReminderRule(minute: _start, every: _every, endMinute: _end);
    return AlertDialog(
      title: const Text('Repeating reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _every,
            decoration: const InputDecoration(labelText: 'Every'),
            items: [
              for (final s in _steps)
                DropdownMenuItem(
                  value: s,
                  child: Text(
                    s < 60
                        ? '$s minutes'
                        : (s % 60 == 0
                              ? '${s ~/ 60} hours'
                              : '${s / 60} hours'),
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _every = v ?? _every),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(true),
                  child: Text('From ${formatMinute(_start)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(false),
                  child: Text('Until ${formatMinute(_end)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valid
                ? '${rule.times.length} reminders a day'
                : '"Until" must be after "From".',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: valid ? () => Navigator.pop(context, rule) : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Choose the reminder sound: phone default, silent, built-in, or any sound
/// on the phone.
class SoundEditor extends StatelessWidget {
  const SoundEditor({super.key, required this.sound, required this.onChanged});

  final String sound;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String value, String label, {IconData? icon}) {
      final selected = sound == value;
      return OutlinedButton.icon(
        style: _chipStyle(selected),
        onPressed: () {
          onChanged(value);
          PhoneSounds.play(value);
        },
        icon: Icon(
          icon ?? (selected ? Icons.volume_up : Icons.music_note_outlined),
          size: 18,
        ),
        label: Text(label),
      );
    }

    final isPhoneSound = sound.startsWith('uri:');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            option('default', 'Phone default', icon: Icons.notifications_none),
            option('silent', 'Silent', icon: Icons.notifications_off_outlined),
            for (final e in builtInSounds.entries)
              option('raw:${e.key}', e.value),
            if (isPhoneSound)
              option(sound, soundLabel(sound), icon: Icons.phone_android),
          ],
        ),
        if (PhoneSounds.supported) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: DC.accentDeep),
            onPressed: () async {
              final picked = await PhoneSounds.pick(
                current: isPhoneSound ? sound : null,
              );
              if (picked != null) onChanged(picked);
            },
            icon: const Icon(Icons.library_music_outlined),
            label: const Text('Choose any sound on your phone'),
          ),
        ],
      ],
    );
  }
}
