/// Four seasonal palettes, following the northern-hemisphere calendar.
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
    final month = date.month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }
}
