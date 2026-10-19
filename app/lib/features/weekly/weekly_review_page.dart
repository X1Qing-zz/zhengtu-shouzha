import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/weekly_report.dart';
import '../../state/app_store.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/compass_mark.dart';

class WeeklyReviewPage extends StatefulWidget {
  const WeeklyReviewPage({super.key, this.initialWeek});

  final DateTime? initialWeek;

  @override
  State<WeeklyReviewPage> createState() => _WeeklyReviewPageState();
}

class _WeeklyReviewPageState extends State<WeeklyReviewPage> {
  late DateTime _weekStart = startOfWeek(widget.initialWeek ?? today());

  bool get _isCurrentWeek => isSameDay(_weekStart, startOfWeek(today()));

  void _shift(int delta) {
    final target = _weekStart.add(Duration(days: delta * 7));
    if (target.isAfter(startOfWeek(today()))) return;
    setState(() => _weekStart = target);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final report = buildWeeklyReport(
      diaries: store.diaries,
      tasks: store.tasks,
      expenses: store.expenses,
      anchor: _weekStart,
    );
    final highlightIndex = report.isCurrentWeek
        ? today().weekday - 1
        : report.mostProductiveDay;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  color: c.inkSoft,
                ),
                const Spacer(),
                Text('WEEKLY REVIEW', style: AppText.eyebrow(color: c.muted, size: 9)),
                const Spacer(),
                IconButton(
                  onPressed: () => _openShare(context, report),
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  color: c.inkSoft,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '这一周，你走了多远',
              style: AppText.serifStyle(size: 30, color: c.ink, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _WeekNav(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _shift(-1),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        report.weekLabel,
                        style: AppText.sans(
                          size: 10,
                          weight: FontWeight.w600,
                          color: c.accent,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        report.rangeLabel,
                        style: AppText.serifStyle(size: 15, color: c.ink, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _WeekNav(
                  icon: Icons.chevron_right_rounded,
                  onTap: _isCurrentWeek ? null : () => _shift(1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _KeywordCard(report: report),
            const SizedBox(height: 14),
            _WeekStats(report: report),
            const SizedBox(height: 26),
            SectionHeading(
              eyebrow: 'Rhythm',
              title: '本周节奏',
              action: _isCurrentWeek
                  ? const TagChip(label: '进行中', color: Color(0xFF5D7058), dense: true)
                  : null,
            ),
            const SizedBox(height: 12),
            PaperCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.task_alt_rounded, size: 14, color: c.moss),
                      const SizedBox(width: 6),
                      Text('完成任务', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: c.moss)),
                      const Spacer(),
                      Text(
                        report.maxDailyDone > 0
                            ? '最多的一天完成 ${report.maxDailyDone} 件'
                            : '这一周还没有完成记录',
                        style: AppText.sans(size: 9.5, color: c.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BarSeries(
                    values: [for (final value in report.dailyDone) value.toDouble()],
                    labels: const ['一', '二', '三', '四', '五', '六', '日'],
                    height: 64,
                    barWidth: 14,
                    color: c.moss,
                    highlightIndex: highlightIndex,
                    highlightColor: c.accent,
                  ),
                  Divider(height: 24, color: c.line.withValues(alpha: 0.6)),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 14, color: c.terra),
                      const SizedBox(width: 6),
                      Text('每日支出', style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: c.terra)),
                      const Spacer(),
                      Text('本周合计 ${money(report.expenseTotal)}', style: AppText.sans(size: 9.5, color: c.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BarSeries(
                    values: report.dailyExpense,
                    labels: const ['一', '二', '三', '四', '五', '六', '日'],
                    height: 64,
                    barWidth: 14,
                    color: c.line,
                    highlightIndex: _maxExpenseIndex(report.dailyExpense),
                    highlightColor: c.terra,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SectionHeading(
              eyebrow: 'Where it went',
              title: '钱花在哪里',
              action: report.expenseTotal > 0
                  ? Text(money(report.expenseTotal), style: AppText.displayStyle(size: 19, color: c.terra))
                  : null,
            ),
            const SizedBox(height: 12),
            if (report.categories.isEmpty)
              _QuietCard(
                icon: Icons.pie_chart_outline_rounded,
                text: '这一周还没有开销记录',
                hint: '记下几笔，就能看见钱的流向',
              )
            else
              PaperCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    DonutChart(
                      slices: [
                        for (final item in report.categories.take(5))
                          DonutSlice(
                            label: item.category.name,
                            value: item.total,
                            color: item.category.color,
                          ),
                      ],
                      size: 132,
                      strokeWidth: 14,
                      centerTitle: '本周',
                      centerValue: compactMoney(report.expenseTotal),
                      centerCaption: '${report.categories.length} 类',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          for (final item in report.categories.take(3))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _CategoryLine(item: item, total: report.expenseTotal),
                            ),
                          if (report.categories.length > 3)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '另有 ${report.categories.length - 3} 类',
                                style: AppText.sans(size: 9.5, color: c.muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 26),
            SectionHeading(
              eyebrow: 'Sprite’s notes',
              title: '手札精灵的建议',
              action: Icon(Icons.auto_awesome, size: 16, color: c.accent),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < report.insights.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InsightCard(index: i + 1, insight: report.insights[i]),
              ),
            const SizedBox(height: 16),
            SectionHeading(eyebrow: 'Highlights', title: '这一周的高光'),
            const SizedBox(height: 12),
            _Highlights(report: report),
            const SizedBox(height: 26),
            PrimaryButton(
              label: '生成分享卡片',
              icon: Icons.ios_share_rounded,
              onPressed: () => _openShare(context, report),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '周报在你的设备上生成，不会上传任何记录',
                style: AppText.sans(size: 9.5, color: c.muted.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _maxExpenseIndex(List<double> values) {
    if (values.isEmpty) return 0;
    var index = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[index]) index = i;
    }
    return index;
  }

  Future<void> _openShare(BuildContext context, WeeklyReport report) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (_) => WeeklyShareDialog(report: report),
    );
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({required this.icon, required this.onTap});

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
          color: enabled ? c.sunken.withValues(alpha: 0.65) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? c.line : Colors.transparent),
        ),
        child: Icon(
          icon,
          size: 19,
          color: enabled ? c.inkSoft : c.muted.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _KeywordCard extends StatelessWidget {
  const _KeywordCard({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.accentSoft.withValues(alpha: c.isDark ? 0.42 : 0.75),
            c.surface,
          ],
        ),
        border: Border.all(color: c.accent.withValues(alpha: 0.18), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.isDark ? 0.28 : 0.05),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('本周关键词', color: c.accent),
                const SizedBox(height: 9),
                Text(
                  report.keyword,
                  style: AppText.serifStyle(
                    size: 44,
                    color: c.ink,
                    height: 1.1,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  report.narrative,
                  style: AppText.sans(size: 12, color: c.inkSoft, height: 1.85),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CompassMark(size: 52, color: c.ink, accent: c.accent, stroke: 1.6),
          ),
        ],
      ),
    );
  }
}

class _WeekStats extends StatelessWidget {
  const _WeekStats({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Row(
        children: [
          _StatCell(value: '${report.taskDone}', label: '完成任务', tone: c.moss),
          _divider(c),
          _StatCell(value: '${report.diaryCount}', label: '手札', tone: c.accent),
          _divider(c),
          _StatCell(value: money(report.expenseTotal), label: '支出', tone: c.terra),
          _divider(c),
          _StatCell(value: '${report.activeDays}', label: '足迹 / 天', tone: c.ink),
        ],
      ),
    );
  }

  Widget _divider(AppColors c) => Container(width: 0.8, height: 30, color: c.line);
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, required this.tone});

  final String value;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppText.displayStyle(size: 21, color: tone, letterSpacing: -0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.sans(size: 9, color: c.muted)),
        ],
      ),
    );
  }
}

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({required this.item, required this.total});

  final WeeklyCategory item;
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
        const SizedBox(width: 6),
        Expanded(
          child: Text(item.category.name, style: AppText.sans(size: 11, color: c.inkSoft)),
        ),
        Text('${percent.toStringAsFixed(0)}%', style: AppText.sans(size: 9, color: c.muted)),
        const SizedBox(width: 7),
        SizedBox(
          width: 58,
          child: Text(
            money(item.total),
            textAlign: TextAlign.right,
            style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: c.ink),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.index, required this.insight});

  final int index;
  final WeeklyInsight insight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (color, icon) = switch (insight.kind) {
      InsightKind.money => (c.terra, Icons.savings_outlined),
      InsightKind.task => (c.moss, Icons.flag_outlined),
      InsightKind.journal => (c.accent, Icons.auto_stories_outlined),
      InsightKind.care => (c.sky, Icons.spa_outlined),
    };
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              IconBadge(icon: icon, color: color, size: 40, iconSize: 18),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 15,
                  height: 15,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.35), width: 0.7),
                  ),
                  child: Text(
                    '$index',
                    style: AppText.sans(size: 7.5, weight: FontWeight.w600, color: color, height: 1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: AppText.serifStyle(size: 15.5, color: c.ink)),
                const SizedBox(height: 5),
                Text(
                  insight.body,
                  style: AppText.sans(size: 11.5, color: c.inkSoft, height: 1.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = <(IconData, Color, String, String)>[];
    if (report.maxDailyDone > 0) {
      final day = report.weekStart.add(Duration(days: report.mostProductiveDay));
      items.add((
        Icons.bolt_rounded,
        c.accent,
        '最投入的一天',
        '${weekdayLabel(day)} · 完成 ${report.maxDailyDone} 件任务',
      ));
    }
    if (report.biggestExpense != null) {
      final expense = report.biggestExpense!;
      items.add((
        Icons.receipt_long_outlined,
        c.terra,
        '最大的一笔',
        '${expense.category} · ${expense.displayNote} · ${money(expense.amount)}',
      ));
    }
    if (report.diaryChars > 0) {
      items.add((
        Icons.edit_note_rounded,
        c.moss,
        '写下的字',
        '本周 ${report.diaryCount} 篇手札，共 ${report.diaryChars} 字',
      ));
    }
    if (items.isEmpty) {
      return _QuietCard(
        icon: Icons.nightlight_outlined,
        text: '这一周还没有高光记录',
        hint: '写下第一行，或者完成一件小事',
      );
    }
    return PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(items[i].$1, size: 16, color: items[i].$2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$3, style: AppText.sans(size: 9.5, color: c.muted)),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$4,
                          style: AppText.sans(size: 12.5, weight: FontWeight.w500, color: c.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i != items.length - 1)
              Divider(height: 1, color: c.line.withValues(alpha: 0.55)),
          ],
        ],
      ),
    );
  }
}

class _QuietCard extends StatelessWidget {
  const _QuietCard({required this.icon, required this.text, required this.hint});

  final IconData icon;
  final String text;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.muted.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: AppText.serifStyle(size: 14, weight: FontWeight.w400, color: c.inkSoft)),
                const SizedBox(height: 4),
                Text(hint, style: AppText.sans(size: 10.5, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyShareDialog extends StatefulWidget {
  const WeeklyShareDialog({super.key, required this.report});

  final WeeklyReport report;

  @override
  State<WeeklyShareDialog> createState() => _WeeklyShareDialogState();
}

class _WeeklyShareDialogState extends State<WeeklyShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('分享卡片还没有准备好');
      final image = await boundary.toImage(pixelRatio: 3.2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('无法生成图片');
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/zhengtu_weekly_${ymd(widget.report.weekStart)}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '我的征途手札周报 · ${widget.report.rangeLabel}',
          subject: '征途手札 · ${widget.report.weekLabel}',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, '分享卡片生成失败，再试一次');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RepaintBoundary(
              key: _cardKey,
              child: WeeklyShareCard(report: widget.report),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _sharing ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('关闭'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _share,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: const Color(0xFF1B140C),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: _sharing
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 1.7),
                        )
                      : const Icon(Icons.ios_share_rounded, size: 17),
                  label: const Text('保存并分享'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeeklyShareCard extends StatelessWidget {
  const WeeklyShareCard({super.key, required this.report, this.width = 340});

  final WeeklyReport report;
  final double width;

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF3EBDD);
    const gold = Color(0xFFD4A46C);

    return Container(
      width: width,
      height: width * 1.25,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2720), Color(0xFF14130F)],
        ),
        border: Border.all(color: gold.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CompassMark(size: 22, color: cream, accent: gold, stroke: 2.6),
                  const SizedBox(width: 8),
                  const Text(
                    '征途手札',
                    style: TextStyle(
                      fontFamily: AppText.serif,
                      fontSize: 11,
                      letterSpacing: 2.4,
                      color: cream,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'WEEKLY',
                    style: TextStyle(
                      fontFamily: AppText.display,
                      fontSize: 8,
                      letterSpacing: 2.4,
                      color: gold.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                '${report.weekLabel} · ${report.rangeLabel}',
                style: TextStyle(fontSize: 8.5, color: cream.withValues(alpha: 0.55), letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Text(
                report.keyword,
                style: const TextStyle(
                  fontFamily: AppText.serif,
                  fontSize: 42,
                  height: 1.15,
                  letterSpacing: 6,
                  color: cream,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.narrative,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.75,
                  color: cream.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 18),
              if (report.maxDailyDone > 0)
                _ShareLine(
                  label: '最投入',
                  value:
                      '${weekdayLabel(report.weekStart.add(Duration(days: report.mostProductiveDay)))} · ${report.maxDailyDone} 件任务',
                ),
              if (report.biggestExpense != null)
                _ShareLine(
                  label: '最大一笔',
                  value:
                      '${report.biggestExpense!.category} · ${money(report.biggestExpense!.amount)}',
                ),
              const Spacer(),
              Row(
                children: [
                  _ShareStat(value: '${report.taskDone}', label: '完成任务', color: gold),
                  _ShareStat(value: '${report.diaryCount}', label: '手札', color: cream),
                  _ShareStat(value: money(report.expenseTotal), label: '支出', color: gold),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 0.6, color: gold.withValues(alpha: 0.25)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '每一步，都算数',
                    style: TextStyle(
                      fontFamily: AppText.serif,
                      fontSize: 9.5,
                      letterSpacing: 2.2,
                      color: cream.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ZHENGTU · SHOUZHA',
                    style: TextStyle(
                      fontFamily: AppText.display,
                      fontSize: 7,
                      letterSpacing: 1.8,
                      color: gold.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareLine extends StatelessWidget {
  const _ShareLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(color: Color(0xFFD4A46C), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 38,
            child: Text(
              label,
              style: TextStyle(fontSize: 8.5, color: const Color(0xFFF3EBDD).withValues(alpha: 0.45)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: const Color(0xFFF3EBDD).withValues(alpha: 0.78)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {  const _ShareStat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppText.display,
                fontSize: 20,
                height: 1,
                color: color,
                fontFeatures: const [ui.FontFeature.liningFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 8, color: const Color(0xFFF3EBDD).withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}
