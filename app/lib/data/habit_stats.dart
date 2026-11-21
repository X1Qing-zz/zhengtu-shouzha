import '../core/date_utils.dart';
import 'models.dart';

/// A makeup day must be in the past and not before the habit started.
bool isHabitMakeupDate(
  DateTime day, {
  required DateTime startDate,
  DateTime? now,
}) {
  final target = dateOnly(day);
  final base = dateOnly(now ?? DateTime.now());
  return target.isBefore(base) && !target.isBefore(dateOnly(startDate));
}

class HabitStats {
  const HabitStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.total,
    required this.thisMonth,
  });

  final int currentStreak;
  final int bestStreak;
  final int total;
  final int thisMonth;
}

HabitStats computeHabitStats(
  Iterable<HabitCheckin> checkins, {
  DateTime? now,
}) {
  final base = now ?? DateTime.now();
  final dates = checkins.map((entry) => ymd(entry.checkinDate)).toSet();
  final monthPrefix = '${base.year}-${two(base.month)}-';

  var cursor = dateOnly(base);
  if (!dates.contains(ymd(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var current = 0;
  while (dates.contains(ymd(cursor))) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final sorted = dates.toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final key in sorted) {
    final day = dateOnly(DateTime.parse(key));
    if (previous != null && day.difference(previous).inDays == 1) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
    previous = day;
  }

  return HabitStats(
    currentStreak: current,
    bestStreak: best,
    total: dates.length,
    thisMonth: dates.where((key) => key.startsWith(monthPrefix)).length,
  );
}
