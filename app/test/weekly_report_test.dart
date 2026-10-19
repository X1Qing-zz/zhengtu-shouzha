import 'package:flutter_test/flutter_test.dart';
import 'package:zhengtu_shouzha/core/date_utils.dart';
import 'package:zhengtu_shouzha/data/models.dart';
import 'package:zhengtu_shouzha/data/weekly_report.dart';

void main() {
  group('iso week numbers', () {
    test('matches known ISO weeks', () {
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      expect(isoWeekNumber(DateTime(2026, 10, 12)), 42);
      expect(isoWeekNumber(DateTime(2025, 12, 31)), 1);
    });
  });

  group('weekly report', () {
    final anchor = DateTime(2026, 10, 18);
    final diaries = [
      DiaryEntry(
        date: DateTime(2026, 10, 12),
        content: '一' * 100,
        createdAt: DateTime(2026, 10, 12, 21),
        updatedAt: DateTime(2026, 10, 12, 21),
      ),
      DiaryEntry(
        date: DateTime(2026, 10, 15),
        content: '二' * 50,
        createdAt: DateTime(2026, 10, 15, 21),
        updatedAt: DateTime(2026, 10, 15, 21),
      ),
      DiaryEntry(
        date: DateTime(2026, 10, 19),
        content: '下周',
        createdAt: DateTime(2026, 10, 19, 21),
        updatedAt: DateTime(2026, 10, 19, 21),
      ),
    ];

    final tasks = [
      TaskItem(
        title: '完成周报',
        done: true,
        completedAt: DateTime(2026, 10, 13, 10),
        createdAt: DateTime(2026, 10, 10),
      ),
      TaskItem(
        title: '跑步',
        done: true,
        completedAt: DateTime(2026, 10, 18, 7),
        createdAt: DateTime(2026, 10, 10),
      ),
      TaskItem(
        title: '上周完成',
        done: true,
        completedAt: DateTime(2026, 10, 11, 7),
        createdAt: DateTime(2026, 10, 1),
      ),
      TaskItem(
        title: '逾期任务',
        dueDate: DateTime(2020, 1, 1),
        createdAt: DateTime(2026, 9, 1),
      ),
    ];

    final expenses = [
      Expense(
        amount: 100,
        category: '餐饮',
        note: '火锅',
        spentAt: DateTime(2026, 10, 12, 19),
        createdAt: DateTime(2026, 10, 12, 19),
      ),
      Expense(
        amount: 50,
        category: '交通',
        note: '地铁',
        spentAt: DateTime(2026, 10, 14, 8),
        createdAt: DateTime(2026, 10, 14, 8),
      ),
      Expense(
        amount: 30,
        category: '购物',
        note: '下周',
        spentAt: DateTime(2026, 10, 20, 8),
        createdAt: DateTime(2026, 10, 20, 8),
      ),
      Expense(
        amount: 200,
        category: '居住',
        note: '上周房租',
        spentAt: DateTime(2026, 10, 8, 8),
        createdAt: DateTime(2026, 10, 8, 8),
      ),
    ];

    final report = buildWeeklyReport(
      diaries: diaries,
      tasks: tasks,
      expenses: expenses,
      anchor: anchor,
    );

    test('bounds the week from Monday to Sunday', () {
      expect(ymd(report.weekStart), '2026-10-12');
      expect(ymd(report.weekEnd), '2026-10-18');
      expect(report.rangeLabel, '10 月 12 日 — 10 月 18 日');
      expect(report.weekLabel, '第 42 周');
    });

    test('aggregates diary, tasks, expenses and active days', () {
      expect(report.diaryCount, 2);
      expect(report.diaryChars, 150);
      expect(report.taskDone, 2);
      expect(report.taskOverdue, 1);
      expect(report.expenseTotal, 150);
      expect(report.previousExpenseTotal, 200);
      expect(report.activeDays, 5);
      expect(report.biggestExpense?.note, '火锅');
      expect(report.categories.first.category.name, '餐饮');
      expect(report.categories.first.total, 100);
    });

    test('fills daily series in Monday-first order', () {
      expect(report.dailyDone, [0, 1, 0, 0, 0, 0, 1]);
      expect(report.dailyExpense, [100, 0, 50, 0, 0, 0, 0]);
      expect(report.maxDailyDone, 1);
    });

    test('writes a keyword and narrative', () {
      expect(report.keyword, '在场');
      expect(report.narrative, contains('完成了 2 件任务'));
      expect(report.narrative, contains('写下 2 篇手札'));
      expect(report.narrative, contains('¥150'));
    });

    test('produces four sprite insights', () {
      expect(report.insights.length, 4);
      expect(report.insights.map((e) => e.kind).toSet(), {
        InsightKind.money,
        InsightKind.task,
        InsightKind.journal,
        InsightKind.care,
      });
      expect(report.insights.first.title, '最大的一笔');
    });
  });

  test('an empty week still gets a gentle report', () {
    final report = buildWeeklyReport(
      diaries: const [],
      tasks: const [],
      expenses: const [],
      anchor: DateTime(2026, 10, 18),
    );
    expect(report.keyword, '留白');
    expect(report.expenseTotal, 0);
    expect(report.insights.length, 4);
    expect(report.narrative, contains('安静'));
  });
}
