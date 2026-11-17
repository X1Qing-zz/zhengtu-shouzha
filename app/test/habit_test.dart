import 'package:flutter_test/flutter_test.dart';
import 'package:zhengtu_shouzha/core/date_utils.dart';
import 'package:zhengtu_shouzha/data/habit_stats.dart';
import 'package:zhengtu_shouzha/data/models.dart';

HabitCheckin _checkin(int day, {int month = 11, int year = 2026}) {
  final date = DateTime(year, month, day);
  return HabitCheckin(
    habitId: 1,
    checkinDate: date,
    checkedAt: DateTime(year, month, day, 20, 30),
  );
}

void main() {
  group('habit models', () {
    test('habit round-trips through a map', () {
      final habit = Habit(
        id: 3,
        title: '健身',
        note: '二十分钟也算',
        type: TaskType.main,
        priority: TaskPriority.high,
        startDate: DateTime(2026, 11, 1),
        createdAt: DateTime(2026, 11, 1, 8),
        updatedAt: DateTime(2026, 11, 7, 8),
      );
      final restored = Habit.fromMap(habit.toMap());
      expect(restored.id, 3);
      expect(restored.title, '健身');
      expect(restored.type, TaskType.main);
      expect(restored.priority, TaskPriority.high);
      expect(ymd(restored.startDate), '2026-11-01');
      expect(restored.archived, isFalse);
    });

    test('check-in round-trips through a map', () {
      final checkin = _checkin(17);
      final restored = HabitCheckin.fromMap(checkin.toMap());
      expect(restored.habitId, 1);
      expect(ymd(restored.checkinDate), '2026-11-17');
      expect(restored.checkedAt.hour, 20);
      expect(restored.checkedAt.minute, 30);
    });
  });

  group('habit stats', () {
    test('counts current streak, best streak and total', () {
      final stats = computeHabitStats(
        [_checkin(15), _checkin(16), _checkin(17)],
        now: DateTime(2026, 11, 17, 22),
      );
      expect(stats.currentStreak, 3);
      expect(stats.bestStreak, 3);
      expect(stats.total, 3);
      expect(stats.thisMonth, 3);
    });

    test('current streak can end yesterday', () {
      final stats = computeHabitStats(
        [_checkin(14), _checkin(15), _checkin(16)],
        now: DateTime(2026, 11, 17, 9),
      );
      expect(stats.currentStreak, 3);
      expect(stats.total, 3);
    });

    test('a gap resets the current streak but not the best', () {
      final stats = computeHabitStats(
        [_checkin(1), _checkin(2), _checkin(5)],
        now: DateTime(2026, 11, 17, 9),
      );
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 2);
      expect(stats.total, 3);
    });

    test('best streak crosses month boundaries', () {
      final stats = computeHabitStats(
        [
          _checkin(31, month: 10),
          _checkin(1),
          _checkin(2),
        ],
        now: DateTime(2026, 11, 2, 22),
      );
      expect(stats.bestStreak, 3);
      expect(stats.currentStreak, 3);
      expect(stats.thisMonth, 2);
    });
  });
}
