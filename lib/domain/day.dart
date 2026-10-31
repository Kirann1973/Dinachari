/// Helpers for working with calendar days.
///
/// Completions are stored per local calendar day as a `yyyy-MM-dd` string so
/// they stay stable across time zones and daylight-saving changes.
library;

/// Strips the time part of [dt], keeping the local calendar day.
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Formats [dt] as a `yyyy-MM-dd` key.
String dayKey(DateTime dt) {
  final d = dateOnly(dt);
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-$m-$day';
}

/// Parses a `yyyy-MM-dd` key back into a local [DateTime].
DateTime parseDayKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Returns the day [n] days before [dt] (calendar arithmetic, DST safe).
DateTime daysBefore(DateTime dt, int n) =>
    DateTime(dt.year, dt.month, dt.day - n);
