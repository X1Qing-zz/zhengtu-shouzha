import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import 'expense_editor.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth => isSameMonth(_month, DateTime.now());

  void _shift(int delta) {
    final target = DateTime(_month.year, _month.month + delta);
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    if (target.isAfter(current)) return;
    setState(() => _month = target);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final entries = store.entriesInMonth(_month);
    final expenses = store.expensesInMonth(_month);
    final incomes = store.incomesInMonth(_month);
    final total = store.monthExpenseTotal(_month);
    final incomeTotal = store.monthIncomeTotal(_month);
    final netTotal = store.monthNetTotal(_month);
    final categories = store.categoryTotals(_month);
    final previous = DateTime(_month.year, _month.month - 1);
    final previousTotal = store.monthExpenseTotal(previous);
    final elapsedDays = _isCurrentMonth ? DateTime.now().day : daysInMonth(_month.year, _month.month);
    final dailyAverage = total / (elapsedDays == 0 ? 1 : elapsedDays);
    final largest = expenses.isEmpty
        ? null
        : expenses.reduce((a, b) => a.amount >= b.amount ? a : b);
    final anchor = _isCurrentMonth
        ? today()
        : DateTime(_month.year, _month.month, daysInMonth(_month.year, _month.month));
    final chartDays = lastDays(anchor, 7);
    final chartValues = chartDays.map((d) => store.expenseTotalOn(d)).toList();
    final highlight = _isCurrentMonth
        ? chartDays.length - 1
        : chartValues.indexWhere((v) => v == chartValues.reduce((a, b) => a > b ? a : b));

    final dayGroups = <String, List<Expense>>{};
    for (final entry in entries) {
      final key = ymd(dateOnly(entry.spentAt));
      dayGroups.putIfAbsent(key, () => []).add(entry);
    }
    final dayKeys = dayGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    final percentChange = previousTotal > 0 ? (total - previousTotal) / previousTotal * 100 : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: FloatingActionButton.extended(
          onPressed: () => showExpenseEditor(context),
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            '记一笔',
            style: AppText.sans(size: 13, weight: FontWeight.w600, color: c.bg),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 150),
          children: [
            Eyebrow('Ledger · 账本', color: c.accent),
            const SizedBox(height: 9),
            Text('日常账本', style: AppText.serifStyle(size: 32, color: c.ink, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(
              '记录每一笔进出 · 本周支出 ${money(store.weekExpenseTotal)} · 收入 ${money(store.weekIncomeTotal)}',
              style: AppText.sans(size: 12, color: c.muted, letterSpacing: 0.3),
            ),
            const SizedBox(height: 22),
            PaperCard(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Eyebrow('Monthly Total', color: c.muted),
                      const Spacer(),
                      _NavButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _shift(-1),
                      ),
                      const SizedBox(width: 6),
                      _NavButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: _isCurrentMonth ? null : () => _shift(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        monthTitle(_month),
                        style: AppText.serifStyle(size: 17, color: c.ink, letterSpacing: 0.5),
                      ),
                      if (_isCurrentMonth) ...[
                        const SizedBox(width: 8),
                        TagChip(label: '本月', color: c.accent, dense: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            money(total),
                            style: AppText.displayStyle(
                              size: 46,
                              color: c.ink,
                              height: 1,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '${expenses.length} 笔支出 · ${incomes.length} 笔收入',
                          style: AppText.sans(size: 11, color: c.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Text(
                        '收入 ${money(incomeTotal)}',
                        style: AppText.sans(size: 11, weight: FontWeight.w500, color: c.moss),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 3, height: 3, decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(
                        '结余 ${money(netTotal)}',
                        style: AppText.sans(
                          size: 11,
                          weight: FontWeight.w600,
                          color: netTotal < 0 ? c.terra : c.inkSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (percentChange == null)
                    Text(
                      previousTotal == 0 ? '上个月还没有账目' : '上月 ${money(previousTotal)}',
                      style: AppText.sans(size: 10.5, color: c.muted),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          percentChange > 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: percentChange > 0 ? c.terra : c.moss,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '较上月 ${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                          style: AppText.sans(
                            size: 10.5,
                            weight: FontWeight.w500,
                            color: percentChange > 0 ? c.terra : c.moss,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '上月 ${money(previousTotal)}',
                          style: AppText.sans(size: 10, color: c.muted),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Container(height: 0.8, color: c.line.withValues(alpha: 0.8)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(label: '日均', value: money(dailyAverage)),
                      ),
                      Container(width: 0.8, height: 28, color: c.line),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: _MiniStat(
                            label: '最大一笔',
                            value: largest == null ? '—' : money(largest.amount),
                          ),
                        ),
                      ),
                      Container(width: 0.8, height: 28, color: c.line),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: _MiniStat(
                            label: '分类',
                            value: '${categories.length} 类',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PaperCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Eyebrow('Where it went', color: c.muted),
                      const Spacer(),
                      if (categories.isNotEmpty)
                        Text(
                          '占比最高 · ${categories.first.category.name}',
                          style: AppText.sans(size: 10, color: c.muted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (categories.isEmpty)
                    const _EmptyCategories()
                  else
                    Row(
                      children: [
                        DonutChart(
                          slices: [
                            for (final item in categories)
                              DonutSlice(
                                label: item.category.name,
                                value: item.total,
                                color: item.category.color,
                              ),
                          ],
                          size: 142,
                          strokeWidth: 15,
                          centerTitle: '支出',
                          centerValue: compactMoney(total),
                          centerCaption: '${categories.length} 类',
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            children: [
                              for (final item in categories.take(4))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: _CategoryLegend(
                                    item: item,
                                    total: total,
                                  ),
                                ),
                              if (categories.length > 4)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '另有 ${categories.length - 4} 类',
                                    style: AppText.sans(size: 9.5, color: c.muted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PaperCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Eyebrow('Rhythm', color: c.muted),
                      const Spacer(),
                      Text(
                        _isCurrentMonth ? '近 7 天' : '${_month.month} 月最后 7 天',
                        style: AppText.sans(size: 10, color: c.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BarSeries(
                    values: chartValues,
                    labels: [for (final day in chartDays) '${day.day}'],
                    height: 92,
                    highlightIndex: highlight,
                    barWidth: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeading(
              eyebrow: 'Details',
              title: '账目明细',
              action: Text(
                '${entries.length} 笔',
                style: AppText.sans(size: 11, color: c.muted),
              ),
            ),
            const SizedBox(height: 12),
            if (dayKeys.isEmpty)
              EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: '这个月还没有账目',
                message: '工资、奖金、一杯咖啡、一趟地铁，\n记下来，才知道钱都去了哪里。',
                actionLabel: '记下第一笔',
                onAction: () => showExpenseEditor(context),
              )
            else
              for (final key in dayKeys) ...[
                _DayGroupHeader(
                  day: parseDate(key),
                  expenseTotal: dayGroups[key]!
                      .where((entry) => !entry.isIncome)
                      .fold(0, (sum, entry) => sum + entry.amount),
                  incomeTotal: dayGroups[key]!
                      .where((entry) => entry.isIncome)
                      .fold(0, (sum, entry) => sum + entry.amount),
                  count: dayGroups[key]!.length,
                ),
                const SizedBox(height: 8),
                PaperCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Column(
                    children: [
                      for (var i = 0; i < dayGroups[key]!.length; i++) ...[
                        _ExpenseRow(
                          expense: dayGroups[key]![i],
                          onTap: () => showExpenseEditor(
                            context,
                            expense: dayGroups[key]![i],
                          ),
                        ),
                        if (i != dayGroups[key]!.length - 1)
                          Divider(height: 1, color: c.line.withValues(alpha: 0.55)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? c.sunken.withValues(alpha: 0.7) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? c.line : Colors.transparent),
        ),
        child: Icon(icon, size: 18, color: enabled ? c.inkSoft : c.muted.withValues(alpha: 0.3)),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.sans(size: 13.5, weight: FontWeight.w600, color: c.ink)),
        const SizedBox(height: 3),
        Text(label, style: AppText.sans(size: 9.5, color: c.muted)),
      ],
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({required this.item, required this.total});

  final CategoryTotal item;
  final double total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final percent = total <= 0 ? 0 : item.total / total * 100;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: item.category.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(item.category.name, style: AppText.sans(size: 11.5, color: c.inkSoft)),
        const Spacer(),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: AppText.sans(size: 9.5, color: c.muted),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 62,
          child: Text(
            money(item.total),
            textAlign: TextAlign.right,
            style: AppText.sans(size: 11, weight: FontWeight.w600, color: c.ink),
          ),
        ),
      ],
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.line, width: 10),
            ),
            child: Icon(Icons.pie_chart_outline_rounded, size: 18, color: c.muted),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              '这个月还没有分类数据。\n记下第一笔，就能看见钱的流向。',
              style: AppText.sans(size: 12, color: c.muted, height: 1.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGroupHeader extends StatelessWidget {
  const _DayGroupHeader({
    required this.day,
    required this.expenseTotal,
    required this.incomeTotal,
    required this.count,
  });

  final DateTime day;
  final double expenseTotal;
  final double incomeTotal;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = isSameDay(day, today()) ? '今天' : dayTitle(day);
    return Row(
      children: [
        Text(label, style: AppText.serifStyle(size: 16, color: c.ink)),
        const SizedBox(width: 6),
        Text(weekdayLabel(day), style: AppText.sans(size: 9.5, color: c.muted)),
        const SizedBox(width: 8),
        Text('$count 笔', style: AppText.sans(size: 9.5, color: c.muted)),
        const Spacer(),
        Text(
          '支出 ${money(expenseTotal)}',
          style: AppText.sans(size: 10.5, weight: FontWeight.w500, color: c.inkSoft),
        ),
        if (incomeTotal > 0) ...[
          const SizedBox(width: 7),
          Text(
            '收入 ${money(incomeTotal)}',
            style: AppText.sans(size: 10.5, weight: FontWeight.w500, color: c.moss),
          ),
        ],
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = expense.meta;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: c.isDark ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, size: 17, color: meta.color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.displayNote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13.5, weight: FontWeight.w500, color: c.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${meta.name} · ${timeHm(expense.spentAt)}',
                    style: AppText.sans(size: 9.5, color: c.muted),
                  ),
                ],
              ),
            ),
            Text(
              '${expense.isIncome ? '+' : '-'}${money(expense.amount)}',
              style: AppText.displayStyle(
                size: 19,
                color: expense.isIncome ? c.moss : c.ink,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
