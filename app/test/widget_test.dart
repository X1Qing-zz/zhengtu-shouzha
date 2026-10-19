import 'package:flutter_test/flutter_test.dart';
import 'package:zhengtu_shouzha/core/date_utils.dart';
import 'package:zhengtu_shouzha/core/formatters.dart';
import 'package:zhengtu_shouzha/data/models.dart';

void main() {
  group('money formatting', () {
    test('drops trailing cents by default', () {
      expect(money(1280), '¥1,280');
    });

    test('keeps meaningful cents', () {
      expect(money(12.5), '¥12.50');
    });

    test('handles negatives', () {
      expect(money(-32.25), '-¥32.25');
    });

    test('compacts large amounts', () {
      expect(compactMoney(12800), '¥1.3w');
    });
  });

  group('date helpers', () {
    test('ymd pads components', () {
      expect(ymd(DateTime(2026, 3, 7)), '2026-03-07');
    });

    test('monday index starts at zero', () {
      expect(mondayIndex(DateTime(2026, 10, 19)), 0);
    });

    test('diary streak counts consecutive days', () {
      final now = DateTime.now();
      final dates = {
        ymd(now),
        ymd(now.subtract(const Duration(days: 1))),
        ymd(now.subtract(const Duration(days: 2))),
      };
      expect(diaryStreak(dates), 3);
    });

    test('diary streak continues from yesterday when today is empty', () {
      final now = DateTime.now();
      final dates = {
        ymd(now.subtract(const Duration(days: 1))),
        ymd(now.subtract(const Duration(days: 2))),
      };
      expect(diaryStreak(dates), 2);
    });

    test('due labels are human readable', () {
      final todayDate = today();
      expect(dueLabel(todayDate), '今天到期');
      expect(dueLabel(todayDate.subtract(const Duration(days: 2))), '逾期 2 天');
    });
  });

  group('models', () {
    test('task round-trips through a map', () {
      final task = TaskItem(
        id: 7,
        title: '跑五公里',
        type: TaskType.side,
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 10, 20),
        createdAt: DateTime(2026, 10, 18, 9, 30),
      );
      final restored = TaskItem.fromMap(task.toMap());
      expect(restored.id, 7);
      expect(restored.title, '跑五公里');
      expect(restored.type, TaskType.side);
      expect(restored.priority, TaskPriority.high);
      expect(ymd(restored.dueDate!), '2026-10-20');
      expect(restored.done, isFalse);
    });

    test('diary round-trips images and mood', () {
      final diary = DiaryEntry(
        id: 1,
        date: DateTime(2026, 10, 18),
        title: '傍晚的风',
        content: '沿着城墙走了一圈。',
        images: const ['/tmp/a.jpg', '/tmp/b.jpg'],
        mood: Mood.joyful,
        createdAt: DateTime(2026, 10, 18, 20),
        updatedAt: DateTime(2026, 10, 18, 21),
      );
      final restored = DiaryEntry.fromMap(diary.toMap());
      expect(restored.images, ['/tmp/a.jpg', '/tmp/b.jpg']);
      expect(restored.mood, Mood.joyful);
      expect(ymd(restored.date), '2026-10-18');
    });

    test('diary display title falls back to content', () {
      final diary = DiaryEntry(
        date: DateTime(2026, 10, 18),
        content: '今天去看了海，风很大，但是很开心。',
        createdAt: DateTime(2026, 10, 18),
        updatedAt: DateTime(2026, 10, 18),
      );
      expect(diary.displayTitle, contains('今天去看了海'));
    });

    test('weather kind maps wmo codes', () {
      expect(weatherKind(0), WeatherKind.sunny);
      expect(weatherKind(3), WeatherKind.cloudy);
      expect(weatherKind(61), WeatherKind.rain);
      expect(weatherKind(95), WeatherKind.thunder);
      expect(conditionLabel(71), '小雪');
    });
  });
}
