/// Which weekdays a habit is due, stored as a bitmask.
/// Bit 0 = Monday … bit 6 = Sunday, matching `DateTime.weekday - 1`.
class Schedule {
  const Schedule(this.mask);

  final int mask;

  static const everyDay = Schedule(127);
  static const weekdays = Schedule(31);
  static const weekends = Schedule(96);

  static const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool on(DateTime day) => mask & (1 << (day.weekday - 1)) != 0;
  bool hasWeekday(int weekday) => mask & (1 << (weekday - 1)) != 0;
  Schedule toggle(int weekday) => Schedule(mask ^ (1 << (weekday - 1)));

  /// Short description, e.g. "Every day", "Weekdays", "Mon, Wed, Fri".
  String get label {
    if (mask == everyDay.mask) return 'Every day';
    if (mask == weekdays.mask) return 'Weekdays';
    if (mask == weekends.mask) return 'Weekends';
    if (mask == 0) return 'No days';
    return [
      for (var i = 0; i < 7; i++)
        if (mask & (1 << i) != 0) dayNames[i],
    ].join(', ');
  }
}
