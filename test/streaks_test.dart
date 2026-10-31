import 'package:dinachari/domain/day.dart';
import 'package:dinachari/domain/streaks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 10);
  Set<String> days(List<int> offsets) => {
    for (final o in offsets) dayKey(daysBefore(today, o)),
  };

  test('no completions means zero streaks', () {
    final s = computeStreaks({}, today: today);
    expect(s.current, 0);
    expect(s.best, 0);
  });

  test('counts consecutive days ending today', () {
    final s = computeStreaks(days([0, 1, 2]), today: today);
    expect(s.current, 3);
    expect(s.best, 3);
  });

  test('streak ending yesterday still counts before today is done', () {
    final s = computeStreaks(days([1, 2]), today: today);
    expect(s.current, 2);
  });

  test('a gap breaks the current streak but best is kept', () {
    final s = computeStreaks(days([0, 3, 4, 5, 6]), today: today);
    expect(s.current, 1);
    expect(s.best, 4);
  });

  test('missing today and yesterday resets current streak', () {
    expect(computeStreaks(days([2, 3]), today: today).current, 0);
  });

  test('works across month boundaries', () {
    final s = computeStreaks({
      '2026-02-27',
      '2026-02-28',
      '2026-03-01',
    }, today: DateTime(2026, 3, 1));
    expect(s.current, 3);
  });

  test('dayKey round-trips', () {
    expect(dayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
    expect(parseDayKey('2026-01-05'), DateTime(2026, 1, 5));
  });
}
