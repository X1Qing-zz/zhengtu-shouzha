import 'dart:math' as math;

import 'season.dart';

const List<String> kWeekdays = ['一', '二', '三', '四', '五', '六', '日'];

String two(int n) => n.toString().padLeft(2, '0');

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime today() => dateOnly(DateTime.now());

String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime parseDate(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed == null ? DateTime.now() : parsed;
}

DateTime? parseDateOrNull(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Monday-first index (0 = Monday) for a date.
int mondayIndex(DateTime d) => d.weekday - 1;

String weekdayLabel(DateTime d) => '周${kWeekdays[d.weekday - 1]}';

String monthTitle(DateTime d) => '${d.year} 年 ${d.month} 月';

String shortMonthTitle(DateTime d) => '${d.year}.${two(d.month)}';

String dayTitle(DateTime d) => '${d.month} 月 ${d.day} 日';

String fullDateLabel(DateTime d) => '${d.year} 年 ${d.month} 月 ${d.day} 日 · ${weekdayLabel(d)}';

String timeHm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

String greetingFor(DateTime now, String name) {
  final minutes = now.hour * 60 + now.minute;
  if (minutes < 5 * 60) return '夜深了，$name，该睡觉了';
  if (minutes < 8 * 60) return '早安，$name';
  if (minutes < 11 * 60 + 30) return '上午好，$name';
  if (minutes < 13 * 60 + 30) return '午安，$name';
  if (minutes < 17 * 60 + 30) return '下午好，$name';
  if (minutes < 22 * 60) return '晚上好，$name';
  return '晚安，$name';
}

String relativeDay(DateTime d, {DateTime? now}) {
  final base = today();
  final delta = dateOnly(d).difference(base).inDays;
  if (delta == 0) return '今天';
  if (delta == 1) return '明天';
  if (delta == -1) return '昨天';
  if (delta == 2) return '后天';
  if (delta > 2 && delta <= 7) return '${delta} 天后';
  if (delta < -1 && delta >= -7) return '${-delta} 天前';
  return dayTitle(d);
}

String dueLabel(DateTime? due, {DateTime? now}) {
  if (due == null) return '无期限';
  final base = today();
  final delta = dateOnly(due).difference(base).inDays;
  if (delta < 0) return '逾期 ${-delta} 天';
  if (delta == 0) return '今天到期';
  if (delta == 1) return '明天到期';
  if (delta <= 7) return '${delta} 天后到期';
  return '${due.month} 月 ${due.day} 日到期';
}

String fileDateStamp(DateTime d) =>
    '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}${two(d.second)}';

int dayOfYear(DateTime d) =>
    d.difference(DateTime(d.year, 1, 1)).inDays + 1;

/// Consecutive diary days ending today (or yesterday, if today isn't written yet).
int diaryStreak(Set<String> dates, {DateTime? now}) {
  if (dates.isEmpty) return 0;
  var cursor = today();
  if (!dates.contains(ymd(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!dates.contains(ymd(cursor))) return 0;
  }
  var streak = 0;
  while (dates.contains(ymd(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Start of the week (Monday) for a date.
DateTime startOfWeek(DateTime d) {
  final base = dateOnly(d);
  return base.subtract(Duration(days: base.weekday - 1));
}

/// ISO-8601 week number (weeks start on Monday).
int isoWeekNumber(DateTime date) {
  final base = dateOnly(date);
  final thursday = base.add(Duration(days: 4 - base.weekday));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final firstThursdayWeekday = firstThursday.weekday;
  final firstThursdayMonday = firstThursday.subtract(Duration(days: firstThursdayWeekday - 1));
  return (thursday.difference(firstThursdayMonday).inDays / 7).floor() + 1;
}

/// Last [count] days up to and including [end].
List<DateTime> lastDays(DateTime end, int count) {
  final base = dateOnly(end);
  return List.generate(count, (i) => base.subtract(Duration(days: count - 1 - i)));
}

String weekdayShort(DateTime d) => kWeekdays[d.weekday - 1];

String monthEnglish(DateTime d) {
  const names = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
  ];
  return names[(d.month - 1).clamp(0, 11)];
}

/// Rough season label used for the home greeting.
String seasonLabel(DateTime d) => Season.of(d).label;

int randomSeedFor(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

int boundedInt(int seed, int max) => max <= 0 ? 0 : math.Random(seed).nextInt(max);
