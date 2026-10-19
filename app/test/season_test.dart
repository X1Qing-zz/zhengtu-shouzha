import 'package:flutter_test/flutter_test.dart';
import 'package:zhengtu_shouzha/core/date_utils.dart';
import 'package:zhengtu_shouzha/core/season.dart';

void main() {
  group('season calendar', () {
    test('maps months to four seasons', () {
      expect(Season.of(DateTime(2026, 1, 15)), Season.winter);
      expect(Season.of(DateTime(2026, 3, 1)), Season.spring);
      expect(Season.of(DateTime(2026, 6, 1)), Season.summer);
      expect(Season.of(DateTime(2026, 9, 1)), Season.autumn);
      expect(Season.of(DateTime(2026, 12, 1)), Season.winter);
    });

    test('season labels line up with the palette', () {
      expect(seasonLabel(DateTime(2026, 4, 1)), '春日');
      expect(seasonLabel(DateTime(2026, 7, 1)), '盛夏');
      expect(seasonLabel(DateTime(2026, 10, 19)), '深秋');
      expect(seasonLabel(DateTime(2026, 12, 1)), '凛冬');
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
