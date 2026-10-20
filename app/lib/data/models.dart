import 'package:flutter/material.dart';

import '../core/date_utils.dart';

enum TaskType {
  main('main', '主线', Icons.flag_outlined),
  side('side', '支线', Icons.explore_outlined);

  const TaskType(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static TaskType fromKey(String? key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return side;
  }
}

enum TaskPriority {
  high('high', '高', 0),
  medium('medium', '中', 1),
  low('low', '低', 2);

  const TaskPriority(this.key, this.label, this.rank);

  final String key;
  final String label;
  final int rank;

  static TaskPriority fromKey(String? key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return medium;
  }
}

enum Mood {
  calm('calm', '平静', '🌿'),
  joyful('joyful', '雀跃', '✨'),
  fired('fired', '昂扬', '🔥'),
  tired('tired', '疲惫', '🌙'),
  low('low', '低落', '🌧');

  const Mood(this.key, this.label, this.emoji);

  final String key;
  final String label;
  final String emoji;

  static Mood? fromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final value in values) {
      if (value.key == key) return value;
    }
    return null;
  }
}

class DiaryEntry {
  const DiaryEntry({
    this.id,
    required this.date,
    this.title = '',
    this.content = '',
    this.images = const [],
    this.mood,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final DateTime date;
  final String title;
  final String content;
  final List<String> images;
  final Mood? mood;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (content.trim().isEmpty) return '这一天的留白';
    final firstLine = content.trim().split('\n').first.trim();
    return firstLine.length > 22 ? '${firstLine.substring(0, 22)}…' : firstLine;
  }

  String get excerpt => content.replaceAll(RegExp(r'\s+'), ' ').trim();

  int get charCount => content.replaceAll(RegExp(r'\s'), '').length;

  DiaryEntry copyWith({
    int? id,
    DateTime? date,
    String? title,
    String? content,
    List<String>? images,
    Mood? mood,
    bool clearMood = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      mood: clearMood ? null : (mood ?? this.mood),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': ymd(date),
        'title': title,
        'content': content,
        'images': images.join('|'),
        'mood': mood?.key ?? '',
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DiaryEntry.fromMap(Map<String, Object?> map) => DiaryEntry(
        id: map['id'] as int?,
        date: parseDate(map['date'] as String? ?? ''),
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        images: (map['images'] as String? ?? '')
            .split('|')
            .where((e) => e.trim().isNotEmpty)
            .toList(),
        mood: Mood.fromKey(map['mood'] as String?),
        createdAt: parseDate(map['created_at'] as String? ?? ''),
        updatedAt: parseDate(map['updated_at'] as String? ?? ''),
      );
}

class TaskItem {
  const TaskItem({
    this.id,
    required this.title,
    this.note = '',
    this.type = TaskType.main,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.done = false,
    this.completedAt,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final String note;
  final TaskType type;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool done;
  final DateTime? completedAt;
  final DateTime createdAt;

  bool get isOverdue {
    if (done || dueDate == null) return false;
    return dateOnly(dueDate!).isBefore(today());
  }

  bool get isDueToday => !done && dueDate != null && isSameDay(dueDate, today());

  bool get isOpen => !done;

  TaskItem copyWith({
    int? id,
    String? title,
    String? note,
    TaskType? type,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDue = false,
    bool? done,
    DateTime? completedAt,
    bool clearCompleted = false,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      dueDate: clearDue ? null : (dueDate ?? this.dueDate),
      done: done ?? this.done,
      completedAt:
          clearCompleted ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'note': note,
        'type': type.key,
        'priority': priority.key,
        'due_date': dueDate == null ? null : ymd(dueDate!),
        'done': done ? 1 : 0,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory TaskItem.fromMap(Map<String, Object?> map) => TaskItem(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        note: map['note'] as String? ?? '',
        type: TaskType.fromKey(map['type'] as String?),
        priority: TaskPriority.fromKey(map['priority'] as String?),
        dueDate: parseDateOrNull(map['due_date'] as String?),
        done: (map['done'] as int? ?? 0) == 1,
        completedAt: parseDateOrNull(map['completed_at'] as String?),
        createdAt: parseDate(map['created_at'] as String? ?? ''),
      );
}

class Expense {
  const Expense({
    this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.spentAt,
    required this.createdAt,
    this.isIncome = false,
  });

  final int? id;
  final double amount;
  final String category;
  final String note;
  final DateTime spentAt;
  final DateTime createdAt;
  final bool isIncome;

  ExpenseCategory get meta => categoryByName(category, income: isIncome);

  String get displayNote => note.trim().isEmpty ? category : note.trim();

  double get signedAmount => isIncome ? amount : -amount;

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? note,
    DateTime? spentAt,
    DateTime? createdAt,
    bool? isIncome,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      spentAt: spentAt ?? this.spentAt,
      createdAt: createdAt ?? this.createdAt,
      isIncome: isIncome ?? this.isIncome,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'spent_at': spentAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'is_income': isIncome ? 1 : 0,
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int?,
        amount: (map['amount'] as num? ?? 0).toDouble(),
        category: map['category'] as String? ?? '其他',
        note: map['note'] as String? ?? '',
        spentAt: parseDate(map['spent_at'] as String? ?? ''),
        createdAt: parseDate(map['created_at'] as String? ?? ''),
        isIncome: map['is_income'] == 1 ||
            map['is_income'] == true ||
            map['type'] == 'income',
      );
}

class ExpenseCategory {
  const ExpenseCategory(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

const List<ExpenseCategory> kExpenseCategories = [
  ExpenseCategory('餐饮', Icons.ramen_dining_outlined, Color(0xFFC2703F)),
  ExpenseCategory('交通', Icons.directions_bus_outlined, Color(0xFF6B8A9A)),
  ExpenseCategory('购物', Icons.shopping_bag_outlined, Color(0xFFB65C67)),
  ExpenseCategory('居住', Icons.home_outlined, Color(0xFF8A7F5C)),
  ExpenseCategory('娱乐', Icons.movie_outlined, Color(0xFF7C6A9E)),
  ExpenseCategory('健康', Icons.favorite_border, Color(0xFF6F8F6A)),
  ExpenseCategory('学习', Icons.menu_book_outlined, Color(0xFFA07A4A)),
  ExpenseCategory('人情', Icons.card_giftcard_outlined, Color(0xFFC08A5A)),
  ExpenseCategory('旅行', Icons.flight_takeoff_outlined, Color(0xFF5E8C8A)),
  ExpenseCategory('其他', Icons.more_horiz, Color(0xFF8C8272)),
];

const List<ExpenseCategory> kIncomeCategories = [
  ExpenseCategory('工资', Icons.account_balance_wallet_outlined, Color(0xFF6F8F6A)),
  ExpenseCategory('奖金', Icons.emoji_events_outlined, Color(0xFFC7A64A)),
  ExpenseCategory('兼职', Icons.work_outline_rounded, Color(0xFF6B8A9A)),
  ExpenseCategory('投资', Icons.trending_up_rounded, Color(0xFF7C6A9E)),
  ExpenseCategory('红包', Icons.redeem_outlined, Color(0xFFC2703F)),
  ExpenseCategory('报销', Icons.receipt_long_outlined, Color(0xFF8A7F5C)),
  ExpenseCategory('其他', Icons.more_horiz, Color(0xFF8C8272)),
];

List<ExpenseCategory> categoriesFor({required bool income}) =>
    income ? kIncomeCategories : kExpenseCategories;

ExpenseCategory categoryByName(String name, {bool income = false}) {
  final categories = categoriesFor(income: income);
  return categories.firstWhere(
    (e) => e.name == name,
    orElse: () => categories.last,
  );
}

enum WeatherKind { sunny, clearNight, partly, cloudy, fog, drizzle, rain, snow, thunder }

String conditionLabel(int code) {
  switch (code) {
    case 0:
      return '晴';
    case 1:
      return '大致晴朗';
    case 2:
      return '多云';
    case 3:
      return '阴';
    case 45:
    case 48:
      return '有雾';
    case 51:
    case 53:
    case 55:
      return '毛毛雨';
    case 56:
    case 57:
      return '冻雨';
    case 61:
      return '小雨';
    case 63:
      return '中雨';
    case 65:
      return '大雨';
    case 66:
    case 67:
      return '冻雨';
    case 71:
      return '小雪';
    case 73:
      return '中雪';
    case 75:
      return '大雪';
    case 77:
      return '米雪';
    case 80:
      return '阵雨';
    case 81:
      return '强阵雨';
    case 82:
      return '暴雨';
    case 85:
    case 86:
      return '阵雪';
    case 95:
      return '雷阵雨';
    case 96:
    case 99:
      return '雷暴冰雹';
    default:
      return '天气未知';
  }
}

WeatherKind weatherKind(int code, {bool isDay = true}) {
  if (code == 0) return isDay ? WeatherKind.sunny : WeatherKind.clearNight;
  if (code == 1 || code == 2) return WeatherKind.partly;
  if (code == 3) return WeatherKind.cloudy;
  if (code == 45 || code == 48) return WeatherKind.fog;
  if (code >= 51 && code <= 57) return WeatherKind.drizzle;
  if (code >= 61 && code <= 67) return WeatherKind.rain;
  if (code >= 71 && code <= 77) return WeatherKind.snow;
  if (code >= 80 && code <= 82) return WeatherKind.rain;
  if (code == 85 || code == 86) return WeatherKind.snow;
  if (code >= 95) return WeatherKind.thunder;
  return WeatherKind.partly;
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.code,
    required this.max,
    required this.min,
    required this.precipProb,
  });

  final DateTime date;
  final int code;
  final double max;
  final double min;
  final int precipProb;

  String get condition => conditionLabel(code);

  WeatherKind get kind => weatherKind(code);

  Map<String, Object?> toJson() => {
        'date': ymd(date),
        'code': code,
        'max': max,
        'min': min,
        'precip': precipProb,
      };

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: parseDate(json['date'] as String? ?? ''),
        code: (json['code'] as num? ?? 0).toInt(),
        max: (json['max'] as num? ?? 0).toDouble(),
        min: (json['min'] as num? ?? 0).toDouble(),
        precipProb: (json['precip'] as num? ?? 0).toInt(),
      );
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.date,
    required this.city,
    required this.temp,
    required this.feelsLike,
    required this.tempMax,
    required this.tempMin,
    required this.code,
    required this.condition,
    required this.humidity,
    required this.wind,
    required this.precipProb,
    required this.isDay,
    required this.advice,
    required this.updatedAt,
    this.forecast = const [],
  });

  final DateTime date;
  final String city;
  final double temp;
  final double feelsLike;
  final double tempMax;
  final double tempMin;
  final int code;
  final String condition;
  final int humidity;
  final double wind;
  final int precipProb;
  final bool isDay;
  final String advice;
  final DateTime updatedAt;
  final List<DailyForecast> forecast;

  WeatherKind get kind => weatherKind(code, isDay: isDay);

  Map<String, dynamic> toJson() => {
        'date': ymd(date),
        'city': city,
        'temp': temp,
        'feels': feelsLike,
        'max': tempMax,
        'min': tempMin,
        'code': code,
        'condition': condition,
        'humidity': humidity,
        'wind': wind,
        'precip': precipProb,
        'isDay': isDay,
        'advice': advice,
        'updatedAt': updatedAt.toIso8601String(),
        'forecast': forecast.map((e) => e.toJson()).toList(),
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) => WeatherSnapshot(
        date: parseDate(json['date'] as String? ?? ''),
        city: json['city'] as String? ?? '',
        temp: (json['temp'] as num? ?? 0).toDouble(),
        feelsLike: (json['feels'] as num? ?? 0).toDouble(),
        tempMax: (json['max'] as num? ?? 0).toDouble(),
        tempMin: (json['min'] as num? ?? 0).toDouble(),
        code: (json['code'] as num? ?? 0).toInt(),
        condition: json['condition'] as String? ?? '',
        humidity: (json['humidity'] as num? ?? 0).toInt(),
        wind: (json['wind'] as num? ?? 0).toDouble(),
        precipProb: (json['precip'] as num? ?? 0).toInt(),
        isDay: json['isDay'] as bool? ?? true,
        advice: json['advice'] as String? ?? '',
        updatedAt: parseDate(json['updatedAt'] as String? ?? ''),
        forecast: ((json['forecast'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DailyForecast.fromJson)
            .toList(),
      );

  WeatherSnapshot copyWith({String? city, String? advice}) => WeatherSnapshot(
        date: date,
        city: city ?? this.city,
        temp: temp,
        feelsLike: feelsLike,
        tempMax: tempMax,
        tempMin: tempMin,
        code: code,
        condition: condition,
        humidity: humidity,
        wind: wind,
        precipProb: precipProb,
        isDay: isDay,
        advice: advice ?? this.advice,
        updatedAt: updatedAt,
        forecast: forecast,
      );
}

class Quote {
  const Quote(this.text, this.author);

  final String text;
  final String author;
}

class CityResult {
  const CityResult({
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String region;
  final double latitude;
  final double longitude;

  String get display => region.isEmpty ? name : '$name · $region';
}
