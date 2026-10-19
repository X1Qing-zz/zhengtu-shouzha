import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../diary/diary_editor.dart';
import 'day_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = today();

  bool get _isCurrentMonth => isSameMonth(_visibleMonth, DateTime.now());

  void _changeMonth(int delta) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    if (target.isAfter(current)) return;
    setState(() {
      _visibleMonth = target;
      _selected = target;
    });
  }

  void _goToday() {
    setState(() {
      _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
      _selected = today();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final month = _visibleMonth;
    final diaryDates = store.diaryDatesInMonth(month);
    final taskDates = store.taskDoneDatesInMonth(month);
    final expenseDates = store.expenseDatesInMonth(month);
    final monthRecordDays = <String>{...diaryDates, ...taskDates, ...expenseDates}.length;
    final diary = store.diaryForDay(_selected);
    final tasks = store.tasksCompletedOn(_selected);
    final expenses = store.expensesOn(_selected);
    final dayTotal = store.expenseTotalOn(_selected);
    final isFuture = dateOnly(_selected).isAfter(today());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
          children: [
            Eyebrow('Calendar · 日历', color: c.accent),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '冒险日历',
                    style: AppText.serifStyle(size: 32, color: c.ink, letterSpacing: 2),
                  ),
                ),
                GestureDetector(
                  onTap: _goToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: c.accentSoft.withValues(alpha: c.isDark ? 0.45 : 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.today_outlined, size: 13, color: c.accent),
                        const SizedBox(width: 5),
                        Text('今天', style: AppText.sans(size: 11, weight: FontWeight.w600, color: c.accent)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${month.month} 月 · 记录 $monthRecordDays 天 · 支出 ${compactMoney(store.monthExpenseTotal(month))}',
              style: AppText.sans(size: 12, color: c.muted, letterSpacing: 0.3),
            ),
            const SizedBox(height: 20),
            PaperCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CalendarNav(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _changeMonth(-1),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              monthTitle(month),
                              style: AppText.serifStyle(size: 19, color: c.ink, letterSpacing: 1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              monthEnglish(month),
                              style: AppText.eyebrow(color: c.muted, size: 8),
                            ),
                          ],
                        ),
                      ),
                      _CalendarNav(
                        icon: Icons.chevron_right_rounded,
                        onTap: _isCurrentMonth ? null : () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Center(
                            child: Text(
                              kWeekdays[i],
                              style: AppText.sans(
                                size: 10,
                                weight: FontWeight.w500,
                                color: i >= 5 ? c.accent.withValues(alpha: 0.7) : c.muted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity > 180) {
                        _changeMonth(-1);
                      } else if (velocity < -180) {
                        _changeMonth(1);
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        );
                      },
                      child: _MonthGrid(
                        key: ValueKey('${month.year}-${month.month}'),
                        month: month,
                        selected: _selected,
                        diaryDates: diaryDates,
                        taskDates: taskDates,
                        expenseDates: expenseDates,
                        onSelect: (day) {
                          setState(() {
                            final now = DateTime.now();
                            final lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0);
                            if (day.isAfter(lastDayOfCurrentMonth)) return;
                            _selected = day;
                            _visibleMonth = DateTime(day.year, day.month);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: c.accent, label: '手札'),
                      const SizedBox(width: 14),
                      _LegendDot(color: c.moss, label: '完成任务'),
                      const SizedBox(width: 14),
                      _LegendDot(color: c.terra, label: '开支'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SelectedDayCard(
              day: _selected,
              diary: diary,
              tasks: tasks,
              expenses: expenses,
              total: dayTotal,
              isFuture: isFuture,
              onOpenDetail: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DayDetailPage(day: _selected)),
              ),
              onWriteDiary: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DiaryEditorPage(entry: diary, initialDate: _selected),
                ),
              ),
              onEditDiary: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DiaryEditorPage(entry: diary, initialDate: _selected),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _MonthSummary(store: store, month: month),
          ],
        ),
      ),
    );
  }
}

class _CalendarNav extends StatelessWidget {
  const _CalendarNav({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? c.sunken.withValues(alpha: 0.6) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? c.inkSoft : c.muted.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.diaryDates,
    required this.taskDates,
    required this.expenseDates,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Set<String> diaryDates;
  final Set<String> taskDates;
  final Set<String> expenseDates;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final first = DateTime(month.year, month.month, 1);
    final leading = mondayIndex(first);
    final start = first.subtract(Duration(days: leading));
    final cells = List.generate(42, (i) => start.add(Duration(days: i)));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: cells.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final day = cells[index];
        final inMonth = day.month == month.month && day.year == month.year;
        final key = ymd(day);
        final isSelected = isSameDay(day, selected);
        final isToday = isSameDay(day, today());
        final isWeekend = day.weekday >= 6;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(day),
          child: Opacity(
            opacity: inMonth ? 1 : 0.32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 31,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? c.ink : Colors.transparent,
                    shape: BoxShape.circle,
                    border: !isSelected && isToday
                        ? Border.all(color: c.accent.withValues(alpha: 0.8), width: 1)
                        : null,
                  ),
                  child: Text(
                    '${day.day}',
                    style: AppText.sans(
                      size: 12.5,
                      weight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? c.bg
                          : isWeekend && inMonth
                              ? c.accent.withValues(alpha: 0.85)
                              : c.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (diaryDates.contains(key))
                        _Dot(color: isSelected ? c.accent : c.accent),
                      if (taskDates.contains(key)) _Dot(color: c.moss),
                      if (expenseDates.contains(key)) _Dot(color: c.terra),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1.2),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: AppText.sans(size: 9.5, color: c.muted)),
      ],
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.day,
    required this.diary,
    required this.tasks,
    required this.expenses,
    required this.total,
    required this.isFuture,
    required this.onOpenDetail,
    required this.onWriteDiary,
    required this.onEditDiary,
  });

  final DateTime day;
  final DiaryEntry? diary;
  final List<TaskItem> tasks;
  final List<Expense> expenses;
  final double total;
  final bool isFuture;
  final VoidCallback onOpenDetail;
  final VoidCallback onWriteDiary;
  final VoidCallback onEditDiary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasAny = diary != null || tasks.isNotEmpty || expenses.isNotEmpty;
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                day.day.toString().padLeft(2, '0'),
                style: AppText.displayStyle(size: 40, color: c.accent, height: 1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSameDay(day, today()) ? '今天' : '${day.month} 月 ${day.day} 日',
                      style: AppText.serifStyle(size: 17, color: c.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${weekdayLabel(day)} · ${isFuture ? '还没到来' : hasAny ? '留下了 ${tasks.length + expenses.length + (diary == null ? 0 : 1)} 条记录' : '还没有记录'}',
                      style: AppText.sans(size: 10, color: c.muted),
                    ),
                  ],
                ),
              ),
              GhostButton(
                label: '详情',
                onPressed: onOpenDetail,
                icon: Icons.arrow_outward_rounded,
              ),
            ],
          ),
          if (!hasAny) ...[
            const SizedBox(height: 18),
            Text(
              isFuture ? '未来还没有发生，先去好好过今天吧。' : '这一天还是一张白纸。',
              style: AppText.serifStyle(
                size: 15,
                weight: FontWeight.w400,
                color: c.muted,
                height: 1.7,
              ),
            ),
            if (!isFuture) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onWriteDiary,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('补写这一天', style: AppText.sans(size: 12, weight: FontWeight.w600, color: c.accent)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 13, color: c.accent),
                  ],
                ),
              ),
            ],
          ] else ...[
            if (diary != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onEditDiary,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 15, color: c.accent),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diary!.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.serifStyle(size: 15, color: c.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            diary!.excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(size: 11.5, color: c.muted, height: 1.7),
                          ),
                        ],
                      ),
                    ),
                    if (diary!.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(diary!.images.first),
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.task_alt_rounded, size: 14, color: c.moss),
                  const SizedBox(width: 7),
                  Text('完成 ${tasks.length} 项任务', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: c.moss)),
                ],
              ),
              const SizedBox(height: 7),
              for (final task in tasks.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 5, left: 21),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(size: 12, color: c.inkSoft),
                        ),
                      ),
                      if (task.completedAt != null)
                        Text(timeHm(task.completedAt!), style: AppText.sans(size: 9.5, color: c.muted)),
                    ],
                  ),
                ),
            ],
            if (expenses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 14, color: c.terra),
                  const SizedBox(width: 7),
                  Text(
                    '支出 ${money(total)} · ${expenses.length} 笔',
                    style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: c.terra),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expenses.take(2).map((e) => e.displayNote).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(size: 10, color: c.muted),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.store, required this.month});

  final AppStore store;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final diaryCount = store.diaryDatesInMonth(month).length;
    final taskCount = store.monthDoneCount(month);
    final expenseCount = store.expensesInMonth(month).length;
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      elevated: false,
      color: c.surface.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow('Monthly Review', color: c.muted),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatBlock(value: '$diaryCount', label: '手札 / 篇', tone: c.accent),
              ),
              Expanded(
                child: StatBlock(value: '$taskCount', label: '完成任务', tone: c.moss),
              ),
              Expanded(
                child: StatBlock(
                  value: '$expenseCount',
                  label: '开销 / 笔',
                  tone: c.terra,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
