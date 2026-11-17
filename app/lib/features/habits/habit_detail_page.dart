import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';
import 'habit_editor.dart';

class HabitDetailPage extends StatefulWidget {
  const HabitDetailPage({super.key, required this.habit});

  final Habit habit;

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  late Habit habit = widget.habit;

  Future<void> _edit(BuildContext context) async {
    await showHabitEditor(context, habit: habit);
    if (!mounted) return;
    final store = context.read<AppStore>();
    for (final candidate in store.habits) {
      if (candidate.id == habit.id) {
        setState(() => habit = candidate);
        break;
      }
    }
  }

  Future<void> _toggle(BuildContext context, AppStore store) async {
    final wasChecked = store.isHabitCheckedOn(habit);
    if (wasChecked) {
      await store.undoHabitCheckin(habit);
      if (!context.mounted) return;
      showAppSnack(context, '已撤销今天的打卡');
      return;
    }
    await store.checkInHabit(habit);
    if (!context.mounted) return;
    final stats = store.habitStats(habit);
    showAppSnack(
      context,
      stats.currentStreak > 1
          ? '打卡成功，连续 ${stats.currentStreak} 天'
          : '打卡成功，今天也前进了一步',
      action: SnackBarAction(
        label: '撤销',
        onPressed: () => store.undoHabitCheckin(habit),
      ),
    );
  }

  Future<void> _archive(BuildContext context, AppStore store) async {
    final archived = !habit.archived;
    final ok = await confirmAction(
      context,
      title: archived ? '归档这个长期任务？' : '恢复到每日打卡？',
      message: archived
          ? '「${habit.title}」会从今日打卡里消失，历史记录仍会保留。'
          : '「${habit.title}」会重新出现在每日打卡里。',
      confirmLabel: archived ? '归档' : '恢复',
    );
    if (!ok || !context.mounted) return;
    await store.setHabitArchived(habit, archived);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(BuildContext context, AppStore store) async {
    final count = store.habitStats(habit).total;
    final ok = await confirmAction(
      context,
      title: '删除这个长期任务？',
      message: '「${habit.title}」以及 $count 条打卡记录都会被删除，无法恢复。\n如果只是暂时不想做，建议用归档。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await store.deleteHabit(habit);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final stats = store.habitStats(habit);
    final todayCheckin = store.habitCheckinOn(habit);
    final checkins = store.habitCheckins
        .where((checkin) => checkin.habitId == habit.id)
        .toList()
      ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
    final checkedDates = checkins.map((entry) => ymd(entry.checkinDate)).toSet();

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
                Text('DAILY CHECK-IN', style: AppText.eyebrow(color: c.muted, size: 9)),
                const Spacer(),
                IconButton(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  color: c.inkSoft,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: c.mossSoft.withValues(alpha: c.isDark ? 0.55 : 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.repeat_rounded, size: 23, color: c.moss),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: AppText.serifStyle(
                          size: 28,
                          color: c.ink,
                          height: 1.25,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TagChip(
                            label: habit.type.label,
                            color: habit.type == TaskType.main ? c.accent : c.moss,
                            dense: true,
                            icon: habit.type.icon,
                          ),
                          Text('每天', style: AppText.sans(size: 10.5, color: c.muted)),
                          if (habit.archived)
                            Text('已归档', style: AppText.sans(size: 10.5, color: c.terra)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (habit.note.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                habit.note,
                style: AppText.sans(size: 12.5, color: c.inkSoft, height: 1.8),
              ),
            ],
            const SizedBox(height: 20),
            _CheckinHero(
              checked: todayCheckin != null,
              checkin: todayCheckin,
              streak: stats.currentStreak,
              onTap: () => _toggle(context, store),
            ),
            const SizedBox(height: 14),
            PaperCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Row(
                children: [
                  _StatCell(value: '${stats.currentStreak}', label: '当前连续', tone: c.moss),
                  _divider(c),
                  _StatCell(value: '${stats.bestStreak}', label: '最长连续', tone: c.accent),
                  _divider(c),
                  _StatCell(value: '${stats.total}', label: '累计次数', tone: c.ink),
                  _divider(c),
                  _StatCell(value: '${stats.thisMonth}', label: '本月打卡', tone: c.sky),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SectionHeading(
              eyebrow: 'Last 30 days',
              title: '最近 30 天',
              action: Text(
                '${checkedDates.length} 次',
                style: AppText.sans(size: 11, color: c.muted),
              ),
            ),
            const SizedBox(height: 12),
            PaperCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: _ThirtyDayGrid(
                checkedDates: checkedDates,
                todayKey: ymd(today()),
              ),
            ),
            const SizedBox(height: 26),
            SectionHeading(
              eyebrow: 'History',
              title: '打卡记录',
              action: Text(
                '${checkins.length} 条',
                style: AppText.sans(size: 11, color: c.muted),
              ),
            ),
            const SizedBox(height: 12),
            if (checkins.isEmpty)
              _EmptyHistory()
            else
              PaperCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < checkins.length && i < 20; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: c.moss,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                fullDateLabel(checkins[i].checkinDate),
                                style: AppText.sans(size: 12, color: c.inkSoft),
                              ),
                            ),
                            Text(
                              timeHm(checkins[i].checkedAt),
                              style: AppText.sans(
                                size: 10,
                                weight: FontWeight.w600,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != checkins.length - 1 && i != 19)
                        Divider(height: 1, color: c.line.withValues(alpha: 0.55)),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 26),
            OutlinedButton.icon(
              onPressed: () => _archive(context, store),
              icon: Icon(
                habit.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
                size: 16,
              ),
              label: Text(habit.archived ? '恢复到每日打卡' : '归档，暂时不显示'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.ink,
                side: BorderSide(color: c.line),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _delete(context, store),
                child: Text(
                  '删除长期任务与全部打卡',
                  style: AppText.sans(size: 12, color: c.terra),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(AppColors c) => Container(width: 0.8, height: 28, color: c.line);
}

class _CheckinHero extends StatelessWidget {
  const _CheckinHero({
    required this.checked,
    required this.checkin,
    required this.streak,
    required this.onTap,
  });

  final bool checked;
  final HabitCheckin? checkin;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = checked ? c.moss : c.accent;
    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tone.withValues(alpha: c.isDark ? 0.22 : 0.15),
          c.surface,
        ],
      ),
      borderColor: tone.withValues(alpha: 0.25),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: checked ? c.moss : c.accentSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: tone.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(
              checked ? Icons.check_rounded : Icons.touch_app_outlined,
              size: 22,
              color: checked ? c.surface : c.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checked ? '今天已打卡' : '今天还没有打卡',
                  style: AppText.serifStyle(
                    size: 18,
                    color: c.ink,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  checked
                      ? '${timeHm(checkin!.checkedAt)} · 连续 $streak 天'
                      : '点一下，记下今天',
                  style: AppText.sans(size: 10.5, color: c.muted),
                ),
              ],
            ),
          ),
          Icon(
            checked ? Icons.undo_rounded : Icons.arrow_forward_rounded,
            size: 18,
            color: tone,
          ),
        ],
      ),
    );
  }
}

class _ThirtyDayGrid extends StatelessWidget {
  const _ThirtyDayGrid({required this.checkedDates, required this.todayKey});

  final Set<String> checkedDates;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final days = lastDays(today(), 30);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        final key = ymd(day);
        final checked = checkedDates.contains(key);
        final isToday = key == todayKey;
        return Container(
          decoration: BoxDecoration(
            color: checked
                ? c.moss.withValues(alpha: c.isDark ? 0.8 : 0.82)
                : c.sunken.withValues(alpha: c.isDark ? 0.72 : 0.62),
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: c.accent, width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: AppText.sans(
                  size: 9.5,
                  weight: FontWeight.w600,
                  color: checked ? c.surface : c.muted,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: checked ? c.surface.withValues(alpha: 0.85) : c.line,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 24, color: c.muted.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(
            '还没有打卡记录',
            style: AppText.serifStyle(size: 14, color: c.muted),
          ),
          const SizedBox(height: 4),
          Text(
            '从今天开始，留下第一条。',
            style: AppText.sans(size: 10.5, color: c.muted),
          ),
        ],
      ),
    );
  }
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
          Text(
            value,
            style: AppText.displayStyle(
              size: 21,
              color: tone,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.sans(size: 9, color: c.muted)),
        ],
      ),
    );
  }
}
