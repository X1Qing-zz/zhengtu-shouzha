import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/weather_glyph.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final weather = store.weather;
    final kind = weather?.kind ?? WeatherKind.partly;
    final colors = WeatherVisuals.gradient(
      kind,
      dark: c.isDark,
      isDay: weather?.isDay ?? true,
    );
    final ink = WeatherVisuals.ink(kind, dark: c.isDark, isDay: weather?.isDay ?? true);
    final soft = WeatherVisuals.softInk(kind, dark: c.isDark, isDay: weather?.isDay ?? true);

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoundAction(
                        icon: Icons.arrow_back_rounded,
                        color: ink,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      _RoundAction(
                        icon: Icons.my_location_rounded,
                        color: ink,
                        onTap: () async {
                          await store.useCurrentLocation();
                          if (!context.mounted) return;
                          final error = store.weatherError;
                          if (error != null) {
                            showAppSnack(context, error);
                          } else {
                            showAppSnack(context, '已定位到 ${store.cityName}');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoundAction(
                        icon: Icons.refresh_rounded,
                        color: ink,
                        onTap: () => store.loadWeather(force: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(Icons.near_me_outlined, size: 14, color: soft),
                      const SizedBox(width: 5),
                      Text(
                        store.cityName,
                        style: AppText.sans(size: 13, weight: FontWeight.w600, color: ink),
                      ),
                      const SizedBox(width: 8),
                      TagChip(
                        label: store.autoLocation ? '自动定位' : '手动城市',
                        color: ink,
                        dense: true,
                      ),
                      const Spacer(),
                      if (store.weatherLoading)
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: soft),
                        )
                      else if (weather != null)
                        Text(
                          '更新于 ${timeHm(weather.updatedAt)}',
                          style: AppText.sans(size: 10, color: soft),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (weather == null)
                    _WeatherEmptyState(
                      loading: store.weatherLoading,
                      error: store.weatherError,
                      ink: ink,
                      soft: soft,
                      onRetry: () => store.loadWeather(force: true),
                      onPickCity: () => _openCitySearch(context),
                    )
                  else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weather.temp.round().toString(),
                                    style: AppText.displayStyle(
                                      size: 86,
                                      color: ink,
                                      height: 0.9,
                                      letterSpacing: -3,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10, left: 3),
                                    child: Text(
                                      '°C',
                                      style: AppText.sans(
                                        size: 17,
                                        weight: FontWeight.w600,
                                        color: soft,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                weather.condition,
                                style: AppText.serifStyle(
                                  size: 23,
                                  weight: FontWeight.w500,
                                  color: ink,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '体感 ${weather.feelsLike.round()}° · 最高 ${weather.tempMax.round()}° / 最低 ${weather.tempMin.round()}°',
                                style: AppText.sans(size: 11.5, color: soft),
                              ),
                            ],
                          ),
                        ),
                        WeatherGlyph(
                          kind: weather.kind,
                          size: 132,
                          color: ink.withValues(alpha: 0.92),
                          accent: weather.isDay ? const Color(0xFFF2C56F) : ink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _WeatherMetaCell(label: '湿度', value: '${weather.humidity}%', color: ink, soft: soft),
                        _WeatherMetaCell(label: '风速', value: '${weather.wind.toStringAsFixed(0)} km/h', color: ink, soft: soft),
                        _WeatherMetaCell(label: '降水', value: '${weather.precipProb}%', color: ink, soft: soft),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: c.isDark ? 0.09 : 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ink.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.explore_outlined, size: 16, color: ink.withValues(alpha: 0.75)),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '今日出行建议',
                                  style: AppText.sans(
                                    size: 9.5,
                                    weight: FontWeight.w600,
                                    color: soft,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  weather.advice,
                                  style: AppText.sans(
                                    size: 12,
                                    color: ink.withValues(alpha: 0.9),
                                    height: 1.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (weather != null && weather.forecast.isNotEmpty) ...[
                  SectionHeading(eyebrow: 'Outlook', title: '未来几天'),
                  const SizedBox(height: 12),
                  PaperCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < weather.forecast.length; i++) ...[
                          _ForecastRow(
                            forecast: weather.forecast[i],
                            isToday: i == 0,
                          ),
                          if (i != weather.forecast.length - 1)
                            Divider(height: 1, color: c.line.withValues(alpha: 0.55)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        label: '使用当前定位',
                        icon: Icons.my_location_rounded,
                        onPressed: () async {
                          await store.useCurrentLocation();
                          if (!context.mounted) return;
                          showAppSnack(context, store.weatherError ?? '天气情报已更新');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GhostButton(
                        label: '选择城市',
                        icon: Icons.location_city_outlined,
                        onPressed: () => _openCitySearch(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  '天气数据由 Open-Meteo 提供，定位仅用于获取当地天气，\n不会上传你的任何记录。',
                  style: AppText.sans(size: 10, color: c.muted.withValues(alpha: 0.75), height: 1.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCitySearch(BuildContext context) {
    showAppSheet<void>(context, const CitySearchSheet());
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }
}

class _WeatherMetaCell extends StatelessWidget {
  const _WeatherMetaCell({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.sans(
              size: 14,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: AppText.sans(size: 9.5, color: soft)),
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({required this.forecast, required this.isToday});

  final DailyForecast forecast;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = isToday
        ? '今天'
        : isSameDay(forecast.date, today().add(const Duration(days: 1)))
            ? '明天'
            : weekdayLabel(forecast.date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              label,
              style: AppText.sans(
                size: 12,
                weight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isToday ? c.ink : c.inkSoft,
              ),
            ),
          ),
          WeatherGlyph(kind: forecast.kind, size: 32, color: c.ink, accent: c.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              forecast.condition,
              style: AppText.sans(size: 12, color: c.inkSoft),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.umbrella_outlined, size: 11, color: c.sky),
              const SizedBox(width: 3),
              Text('${forecast.precipProb}%', style: AppText.sans(size: 10, color: c.sky)),
            ],
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 64,
            child: Text(
              '${forecast.max.round()}° / ${forecast.min.round()}°',
              textAlign: TextAlign.right,
              style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherEmptyState extends StatelessWidget {
  const _WeatherEmptyState({
    required this.loading,
    required this.error,
    required this.ink,
    required this.soft,
    required this.onRetry,
    required this.onPickCity,
  });

  final bool loading;
  final String? error;
  final Color ink;
  final Color soft;
  final VoidCallback onRetry;
  final VoidCallback onPickCity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          if (loading) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: soft),
            ),
            const SizedBox(height: 18),
            Text(
              '正在向天空打听消息…',
              style: AppText.serifStyle(size: 24, color: ink, weight: FontWeight.w500),
            ),
          ] else ...[
            Text(
              '天气情报暂时走丢了',
              style: AppText.serifStyle(size: 26, color: ink, weight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              error ?? '检查一下网络，或者换一个城市试试。',
              style: AppText.sans(size: 12, color: soft, height: 1.7),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GhostButton(label: '再试一次', icon: Icons.refresh_rounded, onPressed: onRetry, tone: ink),
                const SizedBox(width: 10),
                GhostButton(label: '选择城市', icon: Icons.location_city_outlined, onPressed: onPickCity, tone: ink),
              ],
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class CitySearchSheet extends StatefulWidget {
  const CitySearchSheet({super.key});

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  final _controller = TextEditingController();
  List<CityResult> _results = const [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _searched = true;
    });
    final results = await context.read<AppStore>().searchCities(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _select(CityResult city) async {
    final store = context.read<AppStore>();
    final messenger = ScaffoldMessenger.of(context);
    await store.chooseCity(city);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('天气站已切换到 ${city.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: '选择城市',
            subtitle: '自动定位不方便时，可以手动指定',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            style: AppText.sans(size: 14, color: c.ink),
            decoration: fieldDecoration(
              context,
              hint: '输入城市名，例如：杭州',
              prefix: Icon(Icons.search_rounded, size: 18, color: c.muted),
              suffix: IconButton(
                onPressed: _search,
                icon: Icon(Icons.arrow_forward_rounded, size: 18, color: c.accent),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_searched && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  '没有找到这座城市，换个名字试试',
                  style: AppText.sans(size: 12, color: c.muted),
                ),
              ),
            )
          else if (!_searched)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  '输入城市名，寻找那里的天气',
                  style: AppText.sans(size: 12, color: c.muted),
                ),
              ),
            )
          else
            for (final city in _results)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _select(city),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: c.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(city.name, style: AppText.sans(size: 13.5, weight: FontWeight.w600, color: c.ink)),
                              if (city.region.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(city.region, style: AppText.sans(size: 10, color: c.muted)),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 15, color: c.muted),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
