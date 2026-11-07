import 'package:tyme/tyme.dart' as tyme;

/// Four seasonal palettes, following the northern-hemisphere four beginnings.
enum Season {
  spring('春', '春日', '嫩绿与粉', 'Spring'),
  summer('夏', '盛夏', '正绿与蓝', 'Summer'),
  autumn('秋', '深秋', '金黄与橙红', 'Autumn'),
  winter('冬', '凛冬', '雪白与灰蓝', 'Winter');

  const Season(this.shortLabel, this.label, this.paletteName, this.english);

  final String shortLabel;
  final String label;
  final String paletteName;
  final String english;

  static Season of(DateTime date) {
    // Optional screenshot/debug override: --dart-define=SEASON_OVERRIDE=winter
    const override = String.fromEnvironment('SEASON_OVERRIDE');
    if (override.isNotEmpty) {
      for (final season in Season.values) {
        if (season.name == override.toLowerCase()) return season;
      }
    }

    final day = DateTime(date.year, date.month, date.day);
    final edges = _seasonEdgesFor(date.year);
    // Season boundaries switch at local midnight on the solar-term day.
    if (!day.isBefore(edges.winter)) return Season.winter;
    if (!day.isBefore(edges.autumn)) return Season.autumn;
    if (!day.isBefore(edges.summer)) return Season.summer;
    if (!day.isBefore(edges.spring)) return Season.spring;
    return Season.winter;
  }
}

/// Cached four beginnings for each calendar year.
///
/// The dates come from the high-precision solar-term calculation in `tyme`
/// (the sxwnl algorithm), not from a hand-maintained annual table.
final Map<int, _SeasonEdges> _seasonEdgesByYear = <int, _SeasonEdges>{};

_SeasonEdges _seasonEdgesFor(int year) => _seasonEdgesByYear.putIfAbsent(
      year,
      () => _SeasonEdges(
        spring: _solarTermDay(year, 3), // 立春
        summer: _solarTermDay(year, 9), // 立夏
        autumn: _solarTermDay(year, 15), // 立秋
        winter: _solarTermDay(year, 21), // 立冬
      ),
    );

DateTime _solarTermDay(int year, int termIndex) {
  final day = tyme.SolarTerm(year, termIndex).getJulianDay().getSolarDay();
  return DateTime(day.getYear(), day.getMonth(), day.getDay());
}

class _SeasonEdges {
  const _SeasonEdges({
    required this.spring,
    required this.summer,
    required this.autumn,
    required this.winter,
  });

  final DateTime spring;
  final DateTime summer;
  final DateTime autumn;
  final DateTime winter;
}
