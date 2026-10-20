import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_info.dart';
import '../core/date_utils.dart';
import '../data/backup_service.dart';
import '../data/image_store.dart';
import '../data/location_service.dart';
import '../data/models.dart';
import '../data/quotes.dart';
import '../data/repositories.dart';
import '../data/settings_store.dart';
import '../data/weather_service.dart';

class CategoryTotal {
  const CategoryTotal(this.category, this.total);

  final ExpenseCategory category;
  final double total;
}

class AppStore extends ChangeNotifier {
  AppStore._({
    required SettingsStore settings,
    required WeatherService weatherService,
    required LocationService locationService,
    required ImageStore imageStore,
  })  : _settings = settings,
        _weatherService = weatherService,
        _locationService = locationService,
        _imageStore = imageStore;

  static Future<AppStore> create() async {
    final settings = await SettingsStore.create();
    final store = AppStore._(
      settings: settings,
      weatherService: WeatherService(),
      locationService: LocationService(),
      imageStore: ImageStore(),
    );
    await store._loadData();
    if (demoMode) {
      await store._seedDemoData();
    }
    unawaited(store.loadWeather(force: true));
    return store;
  }

  /// Demo builds are compiled with `--dart-define=DEMO_MODE=true` and fill an
  /// empty database with a small, coherent set of entries for screenshots.
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE');

  final SettingsStore _settings;
  final WeatherService _weatherService;
  final LocationService _locationService;
  final ImageStore _imageStore;

  final DiaryRepository _diaryRepo = DiaryRepository();
  final TaskRepository _taskRepo = TaskRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final WeatherRepository _weatherRepo = WeatherRepository();
  final BackupService _backupService = BackupService();

  List<DiaryEntry> _diaries = [];
  List<TaskItem> _tasks = [];
  List<Expense> _expenses = [];

  WeatherSnapshot? _weather;
  bool _weatherLoading = false;
  String? _weatherError;

  int _quoteOffset = 0;

  Future<void> _loadData() async {
    _diaries = await _diaryRepo.all();
    _tasks = await _taskRepo.all();
    _expenses = await _expenseRepo.all();
    _sortDiaries();
    _sortExpenses();
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  String get name => _settings.name;
  bool get onboarded => _settings.onboarded;
  ThemeMode get themeMode => _settings.themeMode;
  bool get autoLocation => _settings.autoLocation;
  String get cityName => _settings.cityName;
  double get latitude => _settings.latitude;
  double get longitude => _settings.longitude;

  Future<void> setName(String value) async {
    await _settings.setName(value);
    notifyListeners();
  }

  Future<void> completeOnboarding({String? name}) async {
    if (name != null && name.trim().isNotEmpty) {
      await _settings.setName(name);
    }
    await _settings.setOnboarded(true);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Weather
  // ---------------------------------------------------------------------------

  WeatherSnapshot? get weather => _weather;
  bool get weatherLoading => _weatherLoading;
  String? get weatherError => _weatherError;

  Future<void> loadWeather({bool force = false}) async {
    if (_weatherLoading) return;
    _weatherLoading = true;
    _weatherError = null;
    notifyListeners();
    try {
      if (force) {
        final cached = await _weatherRepo.findByDate(DateTime.now());
        if (cached != null && _weather == null) {
          _weather = cached;
          notifyListeners();
        }
      } else {
        final cached = await _weatherRepo.findByDate(DateTime.now());
        if (cached != null) {
          _weather = cached;
          return;
        }
      }
      final snapshot = await _weatherService.fetch(
        latitude: _settings.latitude,
        longitude: _settings.longitude,
        cityName: _settings.cityName,
      );
      _weather = snapshot;
      await _weatherRepo.save(snapshot);
    } on WeatherException catch (error) {
      _weatherError = error.message;
    } catch (_) {
      _weatherError = '天气情报暂时不可用，晚点再看看';
    } finally {
      _weatherLoading = false;
      notifyListeners();
    }
  }

  Future<void> useCurrentLocation() async {
    try {
      final position = await _locationService.currentPosition();
      final city = await _weatherService.reverseCity(position.latitude, position.longitude) ??
          _settings.cityName;
      await _settings.setCity(
        name: city,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await _settings.setAutoLocation(true);
      notifyListeners();
      await loadWeather(force: true);
    } on LocationException catch (error) {
      _weatherError = error.message;
      notifyListeners();
    } catch (_) {
      _weatherError = '定位遇到了一点问题，可以手动选择城市';
      notifyListeners();
    }
  }

  Future<void> chooseCity(CityResult city) async {
    await _settings.setCity(
      name: city.name,
      latitude: city.latitude,
      longitude: city.longitude,
    );
    await _settings.setAutoLocation(false);
    _weather = null;
    notifyListeners();
    await loadWeather(force: true);
  }

  Future<void> setAutoLocation(bool value) async {
    await _settings.setAutoLocation(value);
    notifyListeners();
    if (value) {
      await useCurrentLocation();
    }
  }

  DateTime? get lastBackupAt => _settings.lastBackupAt;

  File? get latestBackupFile {
    final path = _settings.lastBackupPath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  Future<File> exportBackup() async {
    final file = await _backupService.export(
      diaries: _diaries,
      tasks: _tasks,
      expenses: _expenses,
      settings: _settings.exportForBackup(),
      appVersion: kAppVersion,
    );
    try {
      final documents = await getApplicationDocumentsDirectory();
      final directory = Directory('${documents.path}/backups');
      await directory.create(recursive: true);
      final latest = File('${directory.path}/latest.zip');
      await file.copy(latest.path);
      await _settings.setLastBackupPath(latest.path);
    } catch (_) {
      // The shareable copy is the primary artifact; a persistent copy is best effort.
    }
    await _settings.setLastBackupAt(DateTime.now());
    notifyListeners();
    return file;
  }

  Future<BackupPackage> readBackup(File file) => _backupService.read(file);

  Future<RestoreResult> restoreBackup(BackupPackage package) async {
    final oldImages = _diaries.expand((entry) => entry.images).toSet();
    final result = await _backupService.restore(package);
    await _settings.importFromBackup(package.settings);
    await _loadData();
    final newImages = _diaries.expand((entry) => entry.images).toSet();
    await _imageStore.deleteFiles(oldImages.difference(newImages));
    _weather = null;
    _weatherError = null;
    notifyListeners();
    unawaited(loadWeather(force: true));
    return result;
  }

  Future<List<CityResult>> searchCities(String query) =>
      _weatherService.searchCities(query);

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  List<DiaryEntry> get diaries => List.unmodifiable(_diaries);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<Expense> get expenses => List.unmodifiable(_expenses);

  DiaryEntry? diaryForDay(DateTime day) {
    for (final entry in _diaries) {
      if (isSameDay(entry.date, day)) return entry;
    }
    return null;
  }

  List<TaskItem> tasksCompletedOn(DateTime day) {
    return _tasks
        .where((task) => task.done && isSameDay(task.completedAt, day))
        .toList()
      ..sort((a, b) => (a.completedAt ?? a.createdAt).compareTo(b.completedAt ?? b.createdAt));
  }

  List<Expense> entriesOn(DateTime day) {
    return _expenses.where((e) => isSameDay(e.spentAt, day)).toList()
      ..sort((a, b) => b.spentAt.compareTo(a.spentAt));
  }

  List<Expense> expensesOn(DateTime day) =>
      entriesOn(day).where((e) => !e.isIncome).toList();

  List<Expense> incomesOn(DateTime day) =>
      entriesOn(day).where((e) => e.isIncome).toList();

  double expenseTotalOn(DateTime day) =>
      expensesOn(day).fold(0, (sum, e) => sum + e.amount);

  double incomeTotalOn(DateTime day) =>
      incomesOn(day).fold(0, (sum, e) => sum + e.amount);

  double netTotalOn(DateTime day) => incomeTotalOn(day) - expenseTotalOn(day);

  List<TaskItem> get todayTasks {
    final day = today();
    final items = _tasks.where((task) {
      if (isSameDay(task.completedAt, day)) return true;
      if (!task.done && isSameDay(task.dueDate, day)) return true;
      if (task.isOverdue) return true;
      return false;
    }).toList();
    items.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      final byPriority = a.priority.rank.compareTo(b.priority.rank);
      if (byPriority != 0) return byPriority;
      return (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? b.createdAt);
    });
    return items;
  }

  List<TaskItem> get openTasks => _tasks.where((t) => t.isOpen).toList();

  int get openTaskCount => _tasks.where((t) => t.isOpen).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;

  int get todayDoneCount =>
      _tasks.where((t) => t.done && isSameDay(t.completedAt, today())).length;

  int get weekDoneCount {
    final start = startOfWeek(today());
    return _tasks
        .where((t) =>
            t.done &&
            t.completedAt != null &&
            !t.completedAt!.isBefore(start) &&
            !t.completedAt!.isAfter(DateTime.now()))
        .length;
  }

  int get weekDiaryCount {
    final start = startOfWeek(today());
    return _diaries.where((entry) => !dateOnly(entry.date).isBefore(start)).length;
  }

  int get totalDoneCount => _tasks.where((t) => t.done).length;

  int get diaryStreakCount =>
      diaryStreak(_diaries.map((e) => ymd(e.date)).toSet());

  int get totalDiaries => _diaries.length;

  int get recordDays {
    final dates = <String>{
      ..._diaries.map((e) => ymd(e.date)),
      ..._tasks.where((t) => t.completedAt != null).map((t) => ymd(t.completedAt!)),
      ..._expenses.map((e) => ymd(e.spentAt)),
    };
    return dates.length;
  }

  List<Expense> entriesInMonth(DateTime month) {
    return _expenses
        .where((e) => e.spentAt.year == month.year && e.spentAt.month == month.month)
        .toList();
  }

  List<Expense> expensesInMonth(DateTime month) =>
      entriesInMonth(month).where((e) => !e.isIncome).toList();

  List<Expense> incomesInMonth(DateTime month) =>
      entriesInMonth(month).where((e) => e.isIncome).toList();

  double monthExpenseTotal(DateTime month) =>
      expensesInMonth(month).fold(0, (sum, e) => sum + e.amount);

  double monthIncomeTotal(DateTime month) =>
      incomesInMonth(month).fold(0, (sum, e) => sum + e.amount);

  double monthNetTotal(DateTime month) =>
      monthIncomeTotal(month) - monthExpenseTotal(month);

  double get todayExpenseTotal => expenseTotalOn(today());

  double get todayIncomeTotal => incomeTotalOn(today());

  double get todayNetTotal => netTotalOn(today());

  double get weekExpenseTotal {
    final start = startOfWeek(today());
    return _expenses
        .where((e) => !e.isIncome && !e.spentAt.isBefore(start))
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get weekIncomeTotal {
    final start = startOfWeek(today());
    return _expenses
        .where((e) => e.isIncome && !e.spentAt.isBefore(start))
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get weekNetTotal => weekIncomeTotal - weekExpenseTotal;

  List<CategoryTotal> categoryTotals(DateTime month) {
    final totals = <String, double>{};
    for (final expense in expensesInMonth(month)) {
      totals.update(expense.category, (v) => v + expense.amount, ifAbsent: () => expense.amount);
    }
    final list = totals.entries
        .map((e) => CategoryTotal(categoryByName(e.key), e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  List<double> dailyExpenseTotals(DateTime end, int days) {
    final result = <double>[];
    for (final day in lastDays(end, days)) {
      result.add(expenseTotalOn(day));
    }
    return result;
  }

  int monthDoneCount(DateTime month) => _tasks
      .where((t) =>
          t.done &&
          t.completedAt != null &&
          t.completedAt!.year == month.year &&
          t.completedAt!.month == month.month)
      .length;

  Set<String> diaryDatesInMonth(DateTime month) => _diaries
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .map((e) => ymd(e.date))
      .toSet();

  Set<String> taskDoneDatesInMonth(DateTime month) => _tasks
      .where((t) =>
          t.done &&
          t.completedAt != null &&
          t.completedAt!.year == month.year &&
          t.completedAt!.month == month.month)
      .map((t) => ymd(t.completedAt!))
      .toSet();

  Set<String> expenseDatesInMonth(DateTime month) => _expenses
      .where((e) => e.spentAt.year == month.year && e.spentAt.month == month.month)
      .map((e) => ymd(e.spentAt))
      .toSet();

  bool hasRecordsOn(DateTime day) =>
      diaryForDay(day) != null ||
      tasksCompletedOn(day).isNotEmpty ||
      entriesOn(day).isNotEmpty;

  // ---------------------------------------------------------------------------
  // Diary
  // ---------------------------------------------------------------------------

  Future<DiaryEntry> saveDiary(DiaryEntry entry) async {
    final saved = await _diaryRepo.upsert(entry);
    final index = _diaries.indexWhere(
      (e) => e.id == saved.id || isSameDay(e.date, saved.date),
    );
    if (index >= 0) {
      _diaries[index] = saved;
    } else {
      _diaries.add(saved);
    }
    _sortDiaries();
    notifyListeners();
    return saved;
  }

  Future<void> deleteDiary(DiaryEntry entry) async {
    if (entry.id == null) return;
    await _diaryRepo.delete(entry.id!);
    await _imageStore.deleteFiles(entry.images);
    _diaries.removeWhere((e) => e.id == entry.id);
    notifyListeners();
  }

  Future<List<String>> pickDiaryImages({int limit = 9}) async {
    try {
      return await _imageStore.pickImages(limit: limit);
    } catch (_) {
      return const [];
    }
  }

  Future<void> deleteImageFiles(Iterable<String> paths) =>
      _imageStore.deleteFiles(paths);

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  Future<TaskItem> saveTask(TaskItem task) async {
    TaskItem saved;
    if (task.id == null) {
      saved = await _taskRepo.insert(task);
      _tasks.add(saved);
    } else {
      await _taskRepo.update(task);
      saved = task;
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index >= 0) {
        _tasks[index] = task;
      }
    }
    _sortTasks();
    notifyListeners();
    return saved;
  }

  Future<void> toggleTask(TaskItem task) async {
    if (task.id == null) return;
    final done = !task.done;
    final updated = task.copyWith(
      done: done,
      completedAt: done ? DateTime.now() : null,
      clearCompleted: !done,
    );
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) _tasks[index] = updated;
    notifyListeners();
    await _taskRepo.setDone(task.id!, done);
    _sortTasks();
    notifyListeners();
  }

  Future<void> deleteTask(TaskItem task) async {
    if (task.id == null) return;
    await _taskRepo.delete(task.id!);
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------------

  Future<Expense> saveExpense(Expense expense) async {
    Expense saved;
    if (expense.id == null) {
      saved = await _expenseRepo.insert(expense);
      _expenses.add(saved);
    } else {
      await _expenseRepo.update(expense);
      saved = expense;
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index >= 0) {
        _expenses[index] = expense;
      }
    }
    _sortExpenses();
    notifyListeners();
    return saved;
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    await _expenseRepo.delete(expense.id!);
    _expenses.removeWhere((e) => e.id == expense.id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Quote
  // ---------------------------------------------------------------------------

  Quote get quote {
    final pool = _quotePool;
    return pool[(dayOfYear(DateTime.now()) + _quoteOffset) % pool.length];
  }

  List<Quote> get _quotePool => [
        ...kQuotes,
        for (final message in _settings.futureMessages) Quote(message, '未来的你'),
      ];

  List<String> get futureMessages => _settings.futureMessages;

  Future<void> addFutureMessage(String text) async {
    await _settings.addFutureMessage(text);
    final trimmed = text.trim();
    final pool = _quotePool;
    final index = pool.lastIndexWhere((quote) => quote.text == trimmed);
    if (index >= 0) {
      _quoteOffset = (index - dayOfYear(DateTime.now())) % pool.length;
    }
    notifyListeners();
  }

  void nextQuote() {
    final pool = _quotePool;
    _quoteOffset = (_quoteOffset + 1) % pool.length;
    notifyListeners();
  }

  Future<void> _seedDemoData() async {
    if (_diaries.isNotEmpty || _tasks.isNotEmpty || _expenses.isNotEmpty) return;
    final base = today();
    DateTime at(int daysAgo, int hour, int minute) {
      final d = base.subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day, hour, minute);
    }

    await _settings.setName('林深');
    await _settings.setOnboarded(true);
    await _settings.setCity(name: '西安', latitude: 34.2583, longitude: 108.9286);
    final images = await _imageStore.copyDemoImages();

    final diaries = <DiaryEntry>[
      DiaryEntry(
        date: at(0, 21, 40),
        title: '把傍晚走成一条长路',
        content: '傍晚没有直接回家，绕到城墙根走了一圈。\n\n'
            '风从护城河那边吹过来，带着一点潮湿的草味。耳机里放着很旧的歌，脚步不自觉地慢下来。\n\n'
            '今天没有完成什么惊天动地的事，但我认真看了一场落日。',
        images: images.isNotEmpty ? [images[0]] : const [],
        mood: Mood.joyful,
        createdAt: at(0, 21, 0),
        updatedAt: at(0, 21, 40),
      ),
      DiaryEntry(
        date: at(1, 22, 10),
        title: '在便利店买到最后一个饭团',
        content: '加班到九点，楼下的便利店只剩最后一个金枪鱼饭团。\n\n'
            '收银员说：“今天也辛苦了。”一句很普通的话，却让这个夜晚软了下来。',
        mood: Mood.calm,
        createdAt: at(1, 22, 0),
        updatedAt: at(1, 22, 10),
      ),
      DiaryEntry(
        date: at(3, 20, 30),
        title: '远处的海是灰蓝色的',
        content: '临时起意坐了两个小时的车去看海。\n\n'
            '没有想象中的蓝，风很大，头发被吹得乱七八糟。但站在防波堤上，忽然觉得很多事都没那么要紧。',
        images: images.length > 1 ? [images[1]] : const [],
        mood: Mood.calm,
        createdAt: at(3, 20, 0),
        updatedAt: at(3, 20, 30),
      ),
      DiaryEntry(
        date: at(8, 18, 20),
        title: '雨天，读书，煮一壶茶',
        content: '下雨，取消了原定的跑步。\n\n'
            '把窗开一条缝，听雨落在空调外机上。读《瓦尔登湖》读到下午，茶凉了两次。\n\n'
            '偶尔这样浪费一天，也很好。',
        mood: Mood.tired,
        createdAt: at(8, 18, 0),
        updatedAt: at(8, 18, 20),
      ),
      DiaryEntry(
        date: at(12, 19, 10),
        title: '第一次做番茄牛腩成功',
        content: '炖了一个半小时，厨房里全是番茄和八角的味道。\n\n'
            '咸淡刚好。给妈妈发照片，她回了一句“看着就好吃”。\n\n'
            '下次回家做给他们吃。',
        mood: Mood.fired,
        createdAt: at(12, 19, 0),
        updatedAt: at(12, 19, 10),
      ),
    ];
    for (final diary in diaries) {
      await _diaryRepo.upsert(diary);
    }

    final tasks = <TaskItem>[
      TaskItem(
        title: '整理作品集第一版',
        note: '先选出六个项目，统一封面风格',
        type: TaskType.main,
        priority: TaskPriority.high,
        dueDate: base,
        createdAt: at(5, 9, 0),
      ),
      TaskItem(
        title: '完成实习周报',
        type: TaskType.main,
        priority: TaskPriority.high,
        done: true,
        completedAt: at(0, 10, 20),
        createdAt: at(3, 9, 0),
      ),
      TaskItem(
        title: '给阳台的绿萝换盆',
        type: TaskType.side,
        priority: TaskPriority.low,
        dueDate: base,
        createdAt: at(4, 18, 0),
      ),
      TaskItem(
        title: '读《瓦尔登湖》30 页',
        type: TaskType.main,
        priority: TaskPriority.medium,
        dueDate: base.add(const Duration(days: 1)),
        createdAt: at(2, 21, 0),
      ),
      TaskItem(
        title: '去城南拍一组胶片',
        note: '记得带上那卷 400 度的胶卷',
        type: TaskType.side,
        priority: TaskPriority.low,
        dueDate: base.add(const Duration(days: 3)),
        createdAt: at(6, 15, 0),
      ),
      TaskItem(
        title: '晨跑 3 公里',
        type: TaskType.side,
        priority: TaskPriority.medium,
        done: true,
        completedAt: at(0, 7, 10),
        createdAt: at(7, 20, 0),
      ),
      TaskItem(
        title: '给妈妈打电话',
        type: TaskType.side,
        priority: TaskPriority.low,
        done: true,
        completedAt: at(1, 21, 0),
        createdAt: at(4, 20, 0),
      ),
      TaskItem(
        title: '提交项目答辩提纲',
        note: '把第三部分的技术路线再补全一点',
        type: TaskType.main,
        priority: TaskPriority.high,
        dueDate: at(2, 0, 0),
        createdAt: at(9, 10, 0),
      ),
      TaskItem(
        title: '学会做番茄牛腩',
        type: TaskType.side,
        priority: TaskPriority.medium,
        createdAt: at(15, 19, 0),
      ),
      TaskItem(
        title: '把旧照片整理进云盘',
        type: TaskType.side,
        priority: TaskPriority.low,
        done: true,
        completedAt: at(3, 22, 0),
        createdAt: at(10, 20, 0),
      ),
    ];
    for (final task in tasks) {
      await _taskRepo.insert(task);
    }

    final expenses = <Expense>[
      Expense(amount: 6500, category: '工资', note: '本月实习工资', spentAt: at(1, 10, 0), createdAt: at(1, 10, 5), isIncome: true),
      Expense(amount: 28.5, category: '餐饮', note: '楼下的牛肉面', spentAt: at(0, 12, 20), createdAt: at(0, 12, 25)),
      Expense(amount: 4, category: '交通', note: '地铁 2 号线', spentAt: at(0, 8, 40), createdAt: at(0, 8, 45)),
      Expense(amount: 129, category: '购物', note: '一束洋桔梗', spentAt: at(0, 18, 10), createdAt: at(0, 18, 12)),
      Expense(amount: 68, category: '餐饮', note: '和朋友吃火锅', spentAt: at(1, 19, 30), createdAt: at(1, 19, 35)),
      Expense(amount: 45, category: '娱乐', note: '电影票', spentAt: at(1, 20, 0), createdAt: at(1, 20, 5)),
      Expense(amount: 89, category: '学习', note: '一本设计画册', spentAt: at(2, 16, 0), createdAt: at(2, 16, 5)),
      Expense(amount: 1200, category: '居住', note: '房租', spentAt: at(5, 9, 0), createdAt: at(5, 9, 5)),
      Expense(amount: 35, category: '健康', note: '游泳馆', spentAt: at(8, 18, 0), createdAt: at(8, 18, 5)),
      Expense(amount: 480, category: '旅行', note: '周末去山里', spentAt: at(10, 10, 0), createdAt: at(10, 10, 5)),
      Expense(amount: 52, category: '餐饮', note: '周末早午餐', spentAt: at(12, 11, 0), createdAt: at(12, 11, 5)),
      Expense(amount: 12, category: '交通', note: '打车回家', spentAt: at(15, 22, 30), createdAt: at(15, 22, 35)),
      Expense(amount: 299, category: '购物', note: '新的帆布鞋', spentAt: at(20, 15, 0), createdAt: at(20, 15, 5)),
    ];
    for (final expense in expenses) {
      await _expenseRepo.insert(expense);
    }

    await _loadData();
    _quoteOffset = 0;
  }

  void _sortDiaries() => _diaries.sort((a, b) => b.date.compareTo(a.date));
  void _sortExpenses() => _expenses.sort((a, b) => b.spentAt.compareTo(a.spentAt));

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      if (a.done) {
        return (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt);
      }
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      final byPriority = a.priority.rank.compareTo(b.priority.rank);
      if (byPriority != 0) return byPriority;
      return (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999));
    });
  }
}
