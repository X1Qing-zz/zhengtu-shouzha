import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/compass_mark.dart';
import '../diary/diary_editor.dart';

class DayDetailPage extends StatefulWidget {
  const DayDetailPage({super.key, required this.day});

  final DateTime day;

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  late DateTime _day = dateOnly(widget.day);

  bool get _canGoForward => _day.isBefore(today());

  void _shift(int delta) {
    final target = _day.add(Duration(days: delta));
    if (target.isAfter(today())) return;
    setState(() => _day = target);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final diary = store.diaryForDay(_day);
    final tasks = store.tasksCompletedOn(_day);
    final expenses = store.expensesOn(_day);
    final total = store.expenseTotalOn(_day);
    final hasAny = diary != null || tasks.isNotEmpty || expenses.isNotEmpty;

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
                Text('DAY IN REVIEW', style: AppText.eyebrow(color: c.muted, size: 9)),
                const Spacer(),
                IconButton(
                  onPressed: _canGoForward ? () => _shift(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  color: _canGoForward ? c.inkSoft : c.muted.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_day.day}',
                          style: AppText.displayStyle(size: 64, color: c.ink, height: 0.9, letterSpacing: -2),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '日',
                            style: AppText.serifStyle(size: 15, color: c.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_day.year} 年 ${_day.month} 月 · ${weekdayLabel(_day)}${isSameDay(_day, today()) ? ' · 今天' : ''}',
                      style: AppText.sans(size: 11.5, color: c.muted, letterSpacing: 0.3),
                    ),
                  ],
                ),
                const Spacer(),
                CompassMark(size: 62, color: c.ink, accent: c.accent, stroke: 1.7),
              ],
            ),
            const SizedBox(height: 20),
            PaperCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              color: c.surface.withValues(alpha: 0.7),
              elevated: false,
              child: Row(
                children: [
                  Expanded(
                    child: _DayStat(
                      value: diary == null ? '0' : '${diary.charCount}',
                      label: '手札字数',
                      color: c.accent,
                      icon: Icons.auto_stories_outlined,
                    ),
                  ),
                  Container(width: 0.8, height: 32, color: c.line),
                  Expanded(
                    child: _DayStat(
                      value: '${tasks.length}',
                      label: '完成任务',
                      color: c.moss,
                      icon: Icons.task_alt_rounded,
                    ),
                  ),
                  Container(width: 0.8, height: 32, color: c.line),
                  Expanded(
                    child: _DayStat(
                      value: money(total),
                      label: '当天支出',
                      color: c.terra,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SectionHeading(
              eyebrow: 'Journal',
              title: '这一页手札',
              actionLabel: diary == null ? null : '编辑',
              onAction: () => _editDiary(context, diary),
            ),
            const SizedBox(height: 10),
            if (diary == null)
              PaperCard(
                onTap: () => _editDiary(context, null),
                padding: const EdgeInsets.all(20),
                color: c.surface.withValues(alpha: 0.55),
                elevated: false,
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 22, color: c.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '这一页还是空白。',
                        style: AppText.serifStyle(size: 15, weight: FontWeight.w400, color: c.muted),
                      ),
                    ),
                    Text('补写', style: AppText.sans(size: 11.5, weight: FontWeight.w600, color: c.accent)),
                  ],
                ),
              )
            else
              PaperCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (diary.mood != null) ...[
                      Row(
                        children: [
                          Text(diary.mood!.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            diary.mood!.label,
                            style: AppText.sans(size: 10.5, color: c.muted),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${diary.charCount} 字',
                            style: AppText.sans(size: 10, color: c.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      diary.displayTitle,
                      style: AppText.serifStyle(size: 21, color: c.ink, height: 1.5),
                    ),
                    if (diary.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        diary.content,
                        style: AppText.sans(size: 14, color: c.inkSoft, height: 2.0),
                      ),
                    ],
                    if (diary.images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: diary.images.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                        itemBuilder: (context, index) {
                          final path = diary.images[index];
                          return GestureDetector(
                            onTap: () => _preview(context, path),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: c.sunken,
                                  child: Icon(Icons.broken_image_outlined, size: 16, color: c.muted),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 26),
            SectionHeading(eyebrow: 'Quests', title: '完成的任务'),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              _QuietRow(
                icon: Icons.task_alt_rounded,
                text: '这一天没有完成的任务记录',
              )
            else
              PaperCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    for (var i = 0; i < tasks.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: c.moss.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_rounded, size: 13, color: c.moss),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tasks[i].title,
                                style: AppText.sans(size: 13.5, color: c.ink),
                              ),
                            ),
                            TagChip(label: tasks[i].type.label, color: c.moss, dense: true),
                            if (tasks[i].completedAt != null) ...[
                              const SizedBox(width: 8),
                              Text(timeHm(tasks[i].completedAt!), style: AppText.sans(size: 9.5, color: c.muted)),
                            ],
                          ],
                        ),
                      ),
                      if (i != tasks.length - 1)
                        Divider(height: 1, color: c.line.withValues(alpha: 0.5)),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 26),
            SectionHeading(
              eyebrow: 'Expenses',
              title: '当天的开销',
              action: expenses.isEmpty
                  ? null
                  : Text(money(total), style: AppText.displayStyle(size: 20, color: c.terra)),
            ),
            const SizedBox(height: 10),
            if (expenses.isEmpty)
              _QuietRow(
                icon: Icons.account_balance_wallet_outlined,
                text: '这一天没有开销记录',
              )
            else
              PaperCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < expenses.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: expenses[i].meta.color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                expenses[i].meta.icon,
                                size: 15,
                                color: expenses[i].meta.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                expenses[i].displayNote,
                                style: AppText.sans(size: 13, color: c.ink),
                              ),
                            ),
                            Text(
                              timeHm(expenses[i].spentAt),
                              style: AppText.sans(size: 9.5, color: c.muted),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              money(expenses[i].amount),
                              style: AppText.sans(size: 12.5, weight: FontWeight.w600, color: c.ink),
                            ),
                          ],
                        ),
                      ),
                      if (i != expenses.length - 1)
                        Divider(height: 1, color: c.line.withValues(alpha: 0.5)),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 30),
            if (hasAny)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _summary(diary, tasks, total),
                    textAlign: TextAlign.center,
                    style: AppText.serifStyle(
                      size: 13,
                      weight: FontWeight.w400,
                      color: c.muted,
                      height: 1.9,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _summary(DiaryEntry? diary, List<TaskItem> tasks, double total) {
    final pieces = <String>[];
    if (diary != null) pieces.add('写下了 ${diary.charCount} 个字');
    if (tasks.isNotEmpty) pieces.add('完成了 ${tasks.length} 件任务');
    if (total > 0) pieces.add('花了 ${money(total)}');
    if (pieces.isEmpty) return '平凡的一天，也值得被记住。';
    return '这一天，你${pieces.join('，')}。\n每一步，都算数。';
  }

  void _editDiary(BuildContext context, DiaryEntry? diary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiaryEditorPage(entry: diary, initialDate: _day),
      ),
    );
  }

  void _preview(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(child: InteractiveViewer(child: Image.file(File(path)))),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayStat extends StatelessWidget {
  const _DayStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.displayStyle(size: 19, color: c.ink, letterSpacing: -0.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppText.sans(size: 9, color: c.muted)),
      ],
    );
  }
}

class _QuietRow extends StatelessWidget {
  const _QuietRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.muted.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Text(text, style: AppText.sans(size: 11.5, color: c.muted)),
        ],
      ),
    );
  }
}
