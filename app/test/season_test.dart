import 'package:flutter_test/flutter_test.dart';
import 'package:zhengtu_shouzha/core/date_utils.dart';
import 'package:zhengtu_shouzha/core/season.dart';

void main() {
  group('season calendar', () {
    test('switches on the four beginnings in 2026', () {
      expect(Season.of(DateTime(2026, 2, 3)), Season.winter);
      expect(Season.of(DateTime(2026, 2, 4)), Season.spring);
      expect(Season.of(DateTime(2026, 5, 4)), Season.spring);
      expect(Season.of(DateTime(2026, 5, 5)), Season.summer);
      expect(Season.of(DateTime(2026, 8, 6)), Season.summer);
      expect(Season.of(DateTime(2026, 8, 7)), Season.autumn);
      expect(Season.of(DateTime(2026, 11, 6)), Season.autumn);
      expect(Season.of(DateTime(2026, 11, 7)), Season.winter);
    });

    test('uses each year’s actual solar-term dates', () {
      // 2025 立春 is Feb 3; 2027 立夏 / 立秋 fall one day later than 2026.
      expect(Season.of(DateTime(2025, 2, 2)), Season.winter);
      expect(Season.of(DateTime(2025, 2, 3)), Season.spring);
      expect(Season.of(DateTime(2027, 5, 5)), Season.spring);
      expect(Season.of(DateTime(2027, 5, 6)), Season.summer);
      expect(Season.of(DateTime(2027, 8, 7)), Season.summer);
      expect(Season.of(DateTime(2027, 8, 8)), Season.autumn);
    });

    test('keeps the whole first day of a new season', () {
      expect(Season.of(DateTime(2026, 11, 7, 0, 0)), Season.winter);
      expect(Season.of(DateTime(2026, 11, 7, 23, 59)), Season.winter);
      expect(Season.of(DateTime(2027, 11, 7, 23, 59)), Season.winter);
    });

    test('season labels line up with the palette', () {
      expect(seasonLabel(DateTime(2026, 4, 1)), '春日');
      expect(seasonLabel(DateTime(2026, 7, 1)), '盛夏');
      expect(seasonLabel(DateTime(2026, 10, 19)), '深秋');
      expect(seasonLabel(DateTime(2026, 11, 7)), '凛冬');
    });
  });

  group('time-aware greeting', () {
    String at(int hour, int minute) =>
        greetingFor(DateTime(2026, 10, 19, hour, minute), '林深');

    test('late night has its own line', () {
      expect(at(0, 0), '夜深了，林深，该睡觉了');
      expect(at(4, 59), '夜深了，林深，该睡觉了');
    });

    test('early morning is 早安', () {
      expect(at(5, 0), '早安，林深');
      expect(at(7, 59), '早安，林深');
    });

    test('mid morning is 上午好', () {
      expect(at(8, 0), '上午好，林深');
      expect(at(11, 29), '上午好，林深');
    });

    test('lunch break is 午安', () {
      expect(at(11, 30), '午安，林深');
      expect(at(13, 29), '午安，林深');
    });

    test('afternoon is 下午好', () {
      expect(at(13, 30), '下午好，林深');
      expect(at(17, 29), '下午好，林深');
    });

    test('evening is 晚上好', () {
      expect(at(17, 30), '晚上好，林深');
      expect(at(21, 59), '晚上好，林深');
    });

    test('late evening winds down with 晚安', () {
      expect(at(22, 0), '晚安，林深');
      expect(at(23, 59), '晚安，林深');
    });
  });
}
