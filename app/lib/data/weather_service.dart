import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class WeatherException implements Exception {
  WeatherException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 15);

  Future<WeatherSnapshot> fetch({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '4',
    });

    late http.Response response;
    try {
      response = await _client.get(uri, headers: {'Accept': 'application/json'}).timeout(_timeout);
    } on TimeoutException {
      throw WeatherException('天气情报传送超时，稍后再试试看');
    } catch (_) {
      throw WeatherException('暂时连不上天气站，检查一下网络吧');
    }

    if (response.statusCode != 200) {
      throw WeatherException('天气站打了个盹（${response.statusCode}）');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WeatherException('收到的天气情报读不懂');
    }

    final current = data['current'];
    final daily = data['daily'];
    if (current is! Map<String, dynamic> || daily is! Map<String, dynamic>) {
      throw WeatherException('天气情报不完整');
    }

    final code = _asInt(current['weather_code']);
    final isDay = _asInt(current['is_day']) == 1;
    final temp = _asDouble(current['temperature_2m']);
    final feels = _asDouble(current['apparent_temperature']);
    final wind = _asDouble(current['wind_speed_10m']);
    final humidity = _asInt(current['relative_humidity_2m']);

    final times = (daily['time'] as List?) ?? const [];
    final codes = (daily['weather_code'] as List?) ?? const [];
    final maxes = (daily['temperature_2m_max'] as List?) ?? const [];
    final mins = (daily['temperature_2m_min'] as List?) ?? const [];
    final precips = (daily['precipitation_probability_max'] as List?) ?? const [];

    final forecasts = <DailyForecast>[];
    for (var i = 0; i < times.length; i++) {
      forecasts.add(DailyForecast(
        date: DateTime.tryParse(times[i] as String? ?? '') ?? DateTime.now(),
        code: _asInt(_at(codes, i)),
        max: _asDouble(_at(maxes, i)),
        min: _asDouble(_at(mins, i)),
        precipProb: _asInt(_at(precips, i)),
      ));
    }

    final todayForecast = forecasts.isNotEmpty ? forecasts.first : null;
    final precipProb = todayForecast?.precipProb ?? 0;
    final tempMax = todayForecast?.max ?? temp;
    final tempMin = todayForecast?.min ?? temp;

    return WeatherSnapshot(
      date: DateTime.now(),
      city: cityName,
      temp: temp,
      feelsLike: feels,
      tempMax: tempMax,
      tempMin: tempMin,
      code: code,
      condition: conditionLabel(code),
      humidity: humidity,
      wind: wind,
      precipProb: precipProb,
      isDay: isDay,
      advice: buildAdvice(
        code: code,
        temp: temp,
        feelsLike: feels,
        wind: wind,
        precipProb: precipProb,
      ),
      updatedAt: DateTime.now(),
      forecast: forecasts,
    );
  }

  Future<List<CityResult>> searchCities(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const [];
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': keyword,
      'count': '8',
      'language': 'zh',
      'format': 'json',
    });
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return const [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      return results.whereType<Map<String, dynamic>>().map((json) {
        final regionParts = <String>[
          if ((json['admin1'] as String?)?.isNotEmpty == true) json['admin1'] as String,
          if ((json['country'] as String?)?.isNotEmpty == true) json['country'] as String,
        ];
        return CityResult(
          name: json['name'] as String? ?? keyword,
          region: regionParts.join(' · '),
          latitude: _asDouble(json['latitude']),
          longitude: _asDouble(json['longitude']),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> reverseCity(double latitude, double longitude) async {
    final uri = Uri.https('api.bigdatacloud.net', '/data/reverse-geocode-client', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'localityLanguage': 'zh',
    });
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final city = (data['city'] as String?)?.trim();
      if (city != null && city.isNotEmpty) return city;
      final locality = (data['locality'] as String?)?.trim();
      if (locality != null && locality.isNotEmpty) return locality;
      final region = (data['principalSubdivision'] as String?)?.trim();
      return (region == null || region.isEmpty) ? null : region;
    } catch (_) {
      return null;
    }
  }

  static dynamic _at(List list, int index) => index < list.length ? list[index] : null;

  static int _asInt(dynamic value) => (value as num?)?.toInt() ?? 0;

  static double _asDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;
}

String buildAdvice({
  required int code,
  required double temp,
  required double feelsLike,
  required double wind,
  required int precipProb,
}) {
  final tips = <String>[];

  if (code >= 95) {
    tips.add('有雷雨，尽量避开空旷处与大树，出门带好雨具');
  } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    tips.add('雨水在路上，带把伞，步子放慢一点');
  } else if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    tips.add('有雪，注意保暖和脚下打滑');
  } else if (code == 45 || code == 48) {
    tips.add('雾气较重，出行留意视线与路况');
  } else if (code == 0 && precipProb < 20) {
    tips.add('天气晴好，适合把计划搬到户外');
  } else if (code == 3) {
    tips.add('天色偏阴，给心情留一盏暖灯');
  }

  if (temp >= 33) {
    tips.add('暑气正盛，避开正午的日头，记得多喝水');
  } else if (temp >= 28) {
    tips.add('有些热，穿透气的衣物，及时补水');
  } else if (temp <= 0) {
    tips.add('寒意很重，围巾、手套和热饮都别落下');
  } else if (temp <= 10) {
    tips.add('气温偏低，出门多加一件外套');
  } else if (temp >= 18 && temp <= 26 && tips.isEmpty) {
    tips.add('温度刚好，是适合出发的一天');
  }

  if (wind >= 32) {
    tips.add('风有点大，外套比风度更可靠');
  }
  if (precipProb >= 55 && tips.length < 2) {
    tips.add('降水概率不低，包里常备一把折叠伞');
  }
  if (feelsLike <= 5 && temp > 5 && tips.length < 2) {
    tips.add('体感比气温更冷，注意防风');
  }

  if (tips.isEmpty) {
    tips.add('天气平稳，按自己的节奏出发就好');
  }
  return '${tips.take(2).join('；')}。';
}
