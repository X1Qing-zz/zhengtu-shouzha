import '../core/date_utils.dart';
import '../core/formatters.dart';
import 'models.dart';

enum InsightKind { money, task, journal, care }

class WeeklyInsight {
  const WeeklyInsight({
    required this.kind,
    required this.title,
    required this.body,
  });

  final InsightKind kind;
  final String title;
  final String body;
}

class WeeklyCategory {
  const WeeklyCategory(this.category, this.total);

  final ExpenseCategory category;
  final double total;
}

class WeeklyReport {
  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.diaryCount,
    required this.diaryChars,
    required this.taskDone,
    required this.taskOpen,
    required this.taskOverdue,
    required this.expenseTotal,
    required this.previousExpenseTotal,
    required this.categories,
    required this.dailyExpense,
    required this.dailyDone,
    required this.activeDays,
    required this.streak,
    required this.biggestExpense,
    required this.keyword,
    required this.narrative,
    required this.insights,
    required this.isCurrentWeek,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int diaryCount;
  final int diaryChars;
  final int taskDone;
  final int taskOpen;
  final int taskOverdue;
  final double expenseTotal;
  final double previousExpenseTotal;
  final List<WeeklyCategory> categories;
  final List<double> dailyExpense;
  final List<int> dailyDone;
  final int activeDays;
  final int streak;
  final Expense? biggestExpense;
  final String keyword;
  final String narrative;
  final List<WeeklyInsight> insights;
  final bool isCurrentWeek;

  String get rangeLabel =>
      '${weekStart.month} 月 ${weekStart.day} 日 — ${weekEnd.month} 月 ${weekEnd.day} 日';

  String get weekLabel => '第 ${isoWeekNumber(weekStart)} 周';

  double? get expenseChange => previousExpenseTotal > 0
      ? (expenseTotal - previousExpenseTotal) / previousExpenseTotal * 100
      : null;

  double get topCategoryShare {
    if (expenseTotal <= 0 || categories.isEmpty) return 0;
    return categories.first.total / expenseTotal * 100;
  }

  int get maxDailyDone => dailyDone.fold(0, (m, v) => v > m ? v : m);

  int get mostProductiveDay {
    if (dailyDone.isEmpty) return 0;
    var index = 0;
    for (var i = 1; i < dailyDone.length; i++) {
      if (dailyDone[i] > dailyDone[index]) index = i;
    }
    return index;
  }
}

WeeklyReport buildWeeklyReport({
  required List<DiaryEntry> diaries,
  required List<TaskItem> tasks,
  required List<Expense> expenses,
  required DateTime anchor,
}) {
  final weekStart = startOfWeek(anchor);
  final weekEnd = weekStart.add(const Duration(days: 6));
  bool inWeek(DateTime date) {
    final day = dateOnly(date);
    return !day.isBefore(weekStart) && !day.isAfter(weekEnd);
  }

  final weekDiaries = diaries.where((entry) => inWeek(entry.date)).toList();
  final weekTasks = tasks
      .where((task) => task.done && task.completedAt != null && inWeek(task.completedAt!))
      .toList();
  final weekEntries = expenses.where((expense) => inWeek(expense.spentAt)).toList();
  final weekExpenses = weekEntries.where((expense) => !expense.isIncome).toList();

  final previousStart = weekStart.subtract(const Duration(days: 7));
  final previousExpenseTotal = expenses
      .where((expense) {
        if (expense.isIncome) return false;
        final day = dateOnly(expense.spentAt);
        return !day.isBefore(previousStart) && day.isBefore(weekStart);
      })
      .fold<double>(0, (sum, expense) => sum + expense.amount);

  final expenseTotal = weekExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  final diaryChars = weekDiaries.fold<int>(0, (sum, entry) => sum + entry.charCount);

  final categoryTotals = <String, double>{};
  for (final expense in weekExpenses) {
    categoryTotals.update(
      expense.category,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }
  final categories = categoryTotals.entries
      .map((entry) => WeeklyCategory(categoryByName(entry.key), entry.value))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  final dailyExpense = List<double>.generate(7, (index) {
    final day = weekStart.add(Duration(days: index));
    return weekExpenses
        .where((expense) => isSameDay(expense.spentAt, day))
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  });
  final dailyDone = List<int>.generate(7, (index) {
    final day = weekStart.add(Duration(days: index));
    return weekTasks.where((task) => isSameDay(task.completedAt, day)).length;
  });

  final activeDates = <String>{
    ...weekDiaries.map((entry) => ymd(entry.date)),
    ...weekTasks.map((task) => ymd(task.completedAt!)),
    ...weekEntries.map((expense) => ymd(expense.spentAt)),
  };

  Expense? biggestExpense;
  for (final expense in weekExpenses) {
    if (biggestExpense == null || expense.amount > biggestExpense.amount) {
      biggestExpense = expense;
    }
  }

  final taskOpen = tasks.where((task) => !task.done).length;
  final taskOverdue = tasks.where((task) => task.isOverdue).length;
  final streak = diaryStreak(diaries.map((entry) => ymd(entry.date)).toSet());

  final keyword = _keywordFor(
    diaryCount: weekDiaries.length,
    taskDone: weekTasks.length,
    activeDays: activeDates.length,
    expenseTotal: expenseTotal,
    previousExpenseTotal: previousExpenseTotal,
  );
  final narrative = _narrativeFor(
    keyword: keyword,
    diaryCount: weekDiaries.length,
    taskDone: weekTasks.length,
    expenseTotal: expenseTotal,
    activeDays: activeDates.length,
  );
  final insights = _insightsFor(
    weekExpenses: weekExpenses,
    biggestExpense: biggestExpense,
    expenseTotal: expenseTotal,
    previousExpenseTotal: previousExpenseTotal,
    taskDone: weekTasks.length,
    taskOverdue: taskOverdue,
    diaryCount: weekDiaries.length,
    diaryChars: diaryChars,
    streak: streak,
    activeDays: activeDates.length,
    categories: categories,
  );

  return WeeklyReport(
    weekStart: weekStart,
    weekEnd: weekEnd,
    diaryCount: weekDiaries.length,
    diaryChars: diaryChars,
    taskDone: weekTasks.length,
    taskOpen: taskOpen,
    taskOverdue: taskOverdue,
    expenseTotal: expenseTotal,
    previousExpenseTotal: previousExpenseTotal,
    categories: categories,
    dailyExpense: dailyExpense,
    dailyDone: dailyDone,
    activeDays: activeDates.length,
    streak: streak,
    biggestExpense: biggestExpense,
    keyword: keyword,
    narrative: narrative,
    insights: insights,
    isCurrentWeek: isSameDay(weekStart, startOfWeek(today())),
  );
}

String _keywordFor({
  required int diaryCount,
  required int taskDone,
  required int activeDays,
  required double expenseTotal,
  required double previousExpenseTotal,
}) {
  if (diaryCount == 0 && taskDone == 0 && expenseTotal == 0) return '留白';
  if (diaryCount >= 4) return '记录';
  if (taskDone >= 5) return '推进';
  if (previousExpenseTotal > 0 && expenseTotal > previousExpenseTotal * 1.3) return '流动';
  if (activeDays >= 5) return '在场';
  return '缓行';
}

String _narrativeFor({
  required String keyword,
  required int diaryCount,
  required int taskDone,
  required double expenseTotal,
  required int activeDays,
}) {
  if (diaryCount == 0 && taskDone == 0 && expenseTotal == 0) {
    return '这一周，手札、任务和账本都安静着。休息也是冒险的一部分，等你想出发的时候，写下第一行就好。';
  }

  final parts = <String>[];
  if (taskDone > 0) parts.add('完成了 $taskDone 件任务');
  if (diaryCount > 0) parts.add('写下 $diaryCount 篇手札');
  if (expenseTotal > 0) parts.add('花掉 ${money(expenseTotal)}');
  final body = parts.join('，');

  const closings = {
    '记录': '把日子写下来，它们就有了重量。',
    '推进': '每一次完成，都是向前的一小步。',
    '流动': '钱是流动的，重要的是知道它去了哪里。',
    '在场': '你几乎每天都在场，这本身就很了不起。',
    '缓行': '慢一点也没关系，路还在。',
    '留白': '空白也是手札的一部分。',
  };
  return '这一周，你$body，在 $activeDays 天里留下了足迹。${closings[keyword] ?? ''}';
}

List<WeeklyInsight> _insightsFor({
  required List<Expense> weekExpenses,
  required Expense? biggestExpense,
  required double expenseTotal,
  required double previousExpenseTotal,
  required int taskDone,
  required int taskOverdue,
  required int diaryCount,
  required int diaryChars,
  required int streak,
  required int activeDays,
  required List<WeeklyCategory> categories,
}) {
  final insights = <WeeklyInsight>[];

  if (weekExpenses.isNotEmpty && biggestExpense != null) {
    final share = expenseTotal > 0 ? biggestExpense.amount / expenseTotal * 100 : 0;
    var body = '「${biggestExpense.displayNote}」${money(biggestExpense.amount)}';
    if (share >= 10) body += '，占本周支出的 ${share.toStringAsFixed(0)}%';
    if (categories.isNotEmpty) body += '。本周花得最多的是${categories.first.category.name}。';
    if (previousExpenseTotal > 0 && expenseTotal > previousExpenseTotal * 1.2) {
      body += '比上周多 ${money(expenseTotal - previousExpenseTotal)}。';
    }
    insights.add(WeeklyInsight(kind: InsightKind.money, title: '最大的一笔', body: body));
  } else {
    insights.add(const WeeklyInsight(
      kind: InsightKind.money,
      title: '钱袋很安静',
      body: '这一周没有开销记录。是过得简单，还是忘了记？下周随手记下几笔，就能看见钱的流向。',
    ));
  }

  if (taskOverdue > 0) {
    insights.add(WeeklyInsight(
      kind: InsightKind.task,
      title: '有 $taskOverdue 条任务在等你',
      body: '挑最小的一件先做三分钟，或者把截止日期重新安排到下周。别让它们一直悬在那里。',
    ));
  } else if (taskDone >= 5) {
    insights.add(WeeklyInsight(
      kind: InsightKind.task,
      title: '推进得很稳',
      body: '这一周完成了 $taskDone 件任务。下周可以给自己留一个完全空白的晚上，作为奖励。',
    ));
  } else if (taskDone > 0) {
    insights.add(WeeklyInsight(
      kind: InsightKind.task,
      title: '小步也算前进',
      body: '完成了 $taskDone 件任务。如果还有余力，下周加一条 15 分钟就能做完的支线。',
    ));
  } else {
    insights.add(const WeeklyInsight(
      kind: InsightKind.task,
      title: '清单有点空',
      body: '这一周没有完成记录。写下三件真正想做的事，不必多，先从最小的一件开始。',
    ));
  }

  if (diaryCount == 0) {
    insights.add(const WeeklyInsight(
      kind: InsightKind.journal,
      title: '手札还空着',
      body: '不必等到值得纪念的日子。今天吃了什么、风吹起来是什么味道，都可以是开头。',
    ));
  } else if (streak >= 3) {
    insights.add(WeeklyInsight(
      kind: InsightKind.journal,
      title: '连续记录 $streak 天',
      body: '你已经连续写了 $streak 天，本周留下 $diaryChars 字。继续写下去，未来的你会感谢现在的记录。',
    ));
  } else {
    insights.add(WeeklyInsight(
      kind: InsightKind.journal,
      title: '留下了 $diaryChars 字',
      body: '这一周写下 $diaryCount 篇手札。试着给其中一天补一张照片，记忆会更立体。',
    ));
  }

  if (activeDays >= 6) {
    insights.add(const WeeklyInsight(
      kind: InsightKind.care,
      title: '也记得休息',
      body: '几乎每天都有记录或任务。给下周留一个没有安排的下午，让灵感有地方落脚。',
    ));
  } else {
    insights.add(const WeeklyInsight(
      kind: InsightKind.care,
      title: '留一点空白',
      body: '不必把每一天都填满。散步、发呆、看云，也是冒险的一部分。',
    ));
  }

  return insights;
}
