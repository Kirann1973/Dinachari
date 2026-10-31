import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/database.dart';
import '../domain/habit_look.dart';
import '../domain/habit_style.dart';
import '../domain/reminder_plan.dart';
import '../domain/schedule.dart';
import '../services/reminders.dart';
import '../providers.dart';
import 'common.dart';
import 'editor_sections.dart';
import 'look_picker.dart';

/// Opens the full-screen editor to add a habit, or edit [existing].
Future<void> openHabitEditor(BuildContext context, {Habit? existing}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => HabitEditorScreen(existing: existing),
    ),
  );
}

class HabitEditorScreen extends ConsumerStatefulWidget {
  const HabitEditorScreen({super.key, this.existing});

  final Habit? existing;

  @override
  ConsumerState<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends ConsumerState<HabitEditorScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _unit = TextEditingController(text: widget.existing?.unit ?? '');
  late String _iconKey = widget.existing?.iconKey ?? 'icon:check_circle';
  late int _color = widget.existing?.color ?? habitColors.first.toARGB32();
  late HabitKind _kind = widget.existing?.kind ?? HabitKind.check;
  late int _target = widget.existing?.target ?? 8;
  late int _days = widget.existing?.days ?? Schedule.everyDay.mask;
  late String _sound = widget.existing?.sound ?? 'default';
  List<ReminderRule> _reminders = [];

  /// Until the user picks an icon, guess it from the name.
  late bool _iconPicked = widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_kind == HabitKind.check) _target = 8;
    final existing = widget.existing;
    if (existing != null) {
      ref.read(habitRepositoryProvider).watchReminders(existing.id).first.then((
        list,
      ) {
        if (!mounted) return;
        setState(() {
          _reminders = [
            for (final r in list)
              ReminderRule(
                minute: r.minute,
                every: r.every,
                endMinute: r.endMinute,
              ),
          ];
        });
      });
    }
    _name.addListener(() {
      setState(() {
        if (!_iconPicked) _iconKey = suggestLook(_name.text);
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && _days != 0;

  Future<void> _save() async {
    if (!_canSave) return;
    final repo = ref.read(habitRepositoryProvider);
    final existing = widget.existing;
    final int id;
    if (existing == null) {
      id = await repo.addHabit(
        name: _name.text,
        iconKey: _iconKey,
        color: _color,
        kind: _kind,
        target: _target,
        unit: _unit.text,
        days: _days,
        sound: _sound,
      );
    } else {
      id = existing.id;
      await repo.updateHabit(
        existing.id,
        name: _name.text,
        iconKey: _iconKey,
        color: _color,
        kind: _kind,
        target: _target,
        unit: _unit.text,
        days: _days,
        sound: _sound,
      );
    }
    await repo.setReminders(id, [
      for (final r in _reminders)
        RemindersCompanion.insert(
          habitId: id,
          minute: r.minute,
          every: Value(r.every),
          endMinute: Value(r.endMinute),
        ),
    ]);
    if (_reminders.isNotEmpty) {
      await ReminderService.instance.requestPermission();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_color);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'New habit' : 'Edit habit',
          style: const TextStyle(
            fontFamily: DC.display,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 32),
        children: [
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    HabitIconChip(
                      iconKey: _iconKey,
                      color: deepOf(color),
                      size: 48,
                      filled: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _name,
                        autofocus: widget.existing == null,
                        maxLength: 60,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(color: DC.ink, fontSize: 16),
                        decoration: _fieldDecoration(
                          label: 'Habit name',
                          hint: 'e.g. Gym, Bath, Drink water',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _Label('How do you track it?'),
                const SizedBox(height: 8),
                SegmentedButton<HabitKind>(
                  style: SegmentedButton.styleFrom(
                    foregroundColor: DC.ink,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: DC.accentDeep,
                    side: const BorderSide(color: DC.line),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: HabitKind.check,
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('Tick it off'),
                    ),
                    ButtonSegment(
                      value: HabitKind.count,
                      icon: Icon(Icons.exposure_plus_1),
                      label: Text('Count it'),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
                if (_kind == HabitKind.count) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: _Label('Daily goal')),
                      IconButton.outlined(
                        tooltip: 'Lower goal',
                        color: DC.ink,
                        onPressed: _target > 1
                            ? () => setState(() => _target--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$_target',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: DC.display,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: DC.ink,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'Raise goal',
                        color: DC.ink,
                        onPressed: _target < 999
                            ? () => setState(() => _target++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _unit,
                    maxLength: 20,
                    style: const TextStyle(color: DC.ink),
                    decoration: _fieldDecoration(
                      label: 'Unit (optional)',
                      hint: 'e.g. glasses, pages, minutes',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Label('Look'),
                const SizedBox(height: 12),
                LookPicker(
                  look: _iconKey,
                  color: color,
                  onChanged: (look) => setState(() {
                    _iconKey = look;
                    _iconPicked = true;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionLabel(
                  'Repeat',
                  trailing: Text(
                    Schedule(_days).label,
                    style: const TextStyle(color: DC.muted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                ScheduleEditor(
                  mask: _days,
                  onChanged: (m) => setState(() => _days = m),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('Reminders'),
                const SizedBox(height: 12),
                RemindersEditor(
                  rules: _reminders,
                  onChanged: (r) => setState(() => _reminders = r),
                ),
                const SizedBox(height: 16),
                const SectionLabel('Reminder sound'),
                const SizedBox(height: 12),
                SoundEditor(
                  sound: _sound,
                  onChanged: (s) => setState(() => _sound = s),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Color'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final c in habitColors)
                      _ColorOption(
                        color: c,
                        selected: c.toARGB32() == _color,
                        onTap: () => setState(() => _color = c.toARGB32()),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DC.accentDeep,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            onPressed: _canSave ? _save : null,
            child: Text(
              widget.existing == null ? 'Add habit' : 'Save changes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: DC.muted),
      hintStyle: const TextStyle(color: DC.faint),
      counterStyle: const TextStyle(color: DC.faint),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DC.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DC.accentDeep, width: 2),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: DC.ink,
    ),
  );
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Color',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: selected ? Border.all(color: DC.ink, width: 3) : null,
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}
