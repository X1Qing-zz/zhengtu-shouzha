import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/season.dart';
import '../../core/season_visuals.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/compass_mark.dart';
import '../../widgets/weather_glyph.dart';
import '../diary/diary_editor.dart';
import '../launch/launch_targets.dart';
import '../ledger/expense_editor.dart';
import '../settings/settings_page.dart';
import '../tasks/task_editor.dart';
import '../weather/weather_page.dart';
import '../weekly/weekly_review_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final now = DateTime.now();
    final todayTasks = store.todayTasks;
    final diary = store.diaryForDay(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.accent,
          backgroundColor: c.surface,
          onRefresh: () => store.loadWeather(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
            children: [
              _HomeHeader(
                name: store.name,
                now: now,
                streak: store.diaryStreakCount,
                quote: store.quote,
                onAddMessage: () => _addFutureMessage(context, store),
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
              const SizedBox(height: 18),
              WeatherCard(
                weather: store.weather,
                loading: store.weatherLoading,
                error: store.weatherError,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WeatherPage()),
                ),
                onRetry: () => store.loadWeather(force: true),
              ),
              const SizedBox(height: 26),
              SectionHeading(
                eyebrow: 'TODAY · QUESTS',
                title: '今日任务',
                actionLabel: '全部',
                onAction: () => onNavigate(1),
              ),
              const SizedBox(height: 12),
              if (todayTasks.isEmpty)
                _EmptyTaskCard(onAdd: () => showTaskEditor(context))
              else
                PaperCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: [
                      for (var i = 0; i < todayTasks.length && i < 4; i++) ...[
                        _HomeTaskRow(
                          task: todayTasks[i],
                          onToggle: () => _toggleTask(context, store, todayTasks[i]),
                          onEdit: () => showTaskEditor(context, task: todayTasks[i]),
                        ),
                        if (i != todayTasks.length - 1 && i != 3)
                          Divider(height: 1, color: c.line.withValues(alpha: 0.6)),
                      ],
                      if (todayTasks.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: TextButton(
                            onPressed: () => onNavigate(1),
                            child: Text('还有 ${todayTasks.length - 4} 条任务'),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 26),
              SectionHeading(
                eyebrow: 'JOURNAL',
                title: '今日手札',
                actionLabel: diary == null ? null : '编辑',
                onAction: () => _openDiary(context, diary),
              ),
              const SizedBox(height: 12),
              if (diary == null)
                _DiaryPromptCard(onWrite: () => _openDiary(context, null))
              else
                _DiaryPreviewCard(entry: diary, onTap: () => _openDiary(context, diary)),
              const SizedBox(height: 26),
              SectionHeading(
                eyebrow: 'EXPENSES',
                title: '今日开销',
                actionLabel: '账本',
                onAction: () => onNavigate(3),
              ),
              const SizedBox(height: 12),
              _ExpenseCard(
                total: store.todayExpenseTotal,
                count: store.expensesOn(now).length,
                monthTotal: store.monthExpenseTotal(now),
                series: store.dailyExpenseTotals(now, 7),
                onTap: () => onNavigate(3),
                onAdd: () => showExpenseEditor(context),
              ),
              const SizedBox(height: 26),
              _WeeklyEntry(
                taskDone: store.weekDoneCount,
                diaries: store.weekDiaryCount,
                expenses: store.weekExpenseTotal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WeeklyReviewPage()),
                ),
              ),
              const SizedBox(height: 34),
              Center(
                child: Column(
                  children: [
                    CompassMark(size: 26, color: c.muted, accent: c.accent, stroke: 2.2),
                    const SizedBox(height: 10),
                    Text(
                      '每一步，都算数',
                      style: AppText.serifStyle(
                        size: 12,
                        weight: FontWeight.w400,
                        color: c.muted,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTask(BuildContext context, AppStore store, TaskItem task) async {
    final wasDone = task.done;
    await store.toggleTask(task);
    if (!context.mounted) return;
    if (!wasDone) {
      showAppSnack(
        context,
        '完成「${task.title}」，又前进一格',
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => store.toggleTask(task.copyWith(done: true, completedAt: DateTime.now())),
        ),
      );
    }
  }

  void _openDiary(BuildContext context, DiaryEntry? entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiaryEditorPage(entry: entry, initialDate: today()),
      ),
    );
  }

  Future<void> _addFutureMessage(BuildContext context, AppStore store) async {
    final text = await showAppSheet<String>(
      context,
      const _FutureMessageSheet(),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    await store.addFutureMessage(text);
    if (!context.mounted) return;
    showAppSnack(context, '写好了，未来的你会随机读到它');
  }
}

class _FutureMessageSheet extends StatefulWidget {
  const _FutureMessageSheet();

  @override
  State<_FutureMessageSheet> createState() => _FutureMessageSheetState();
}

class _FutureMessageSheetState extends State<_FutureMessageSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: c.line.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
                child: Icon(Icons.mail_outline_rounded, size: 17, color: c.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('给未来的自己', style: AppText.serifStyle(size: 20, color: c.ink)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: c.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '把此刻想说的话放进谏言池，未来的某一天它会随机出现。',
            style: AppText.sans(size: 11.5, color: c.muted, height: 1.7),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            maxLength: 200,
            textInputAction: TextInputAction.newline,
            style: AppText.serifStyle(size: 15, color: c.ink, height: 1.7, weight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: '比如：别怕，你已经在路上了。',
              hintStyle: AppText.serifStyle(
                size: 14,
                color: c.muted,
                height: 1.6,
                weight: FontWeight.w400,
              ),
              counterStyle: AppText.sans(size: 9, color: c.muted),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final value = _controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(context, value);
              },
              child: const Text('收进手札'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.now,
    required this.streak,
    required this.quote,
    required this.onAddMessage,
    required this.onSettings,
  });

  final String name;
  final DateTime now;
  final int streak;
  final Quote quote;
  final VoidCallback onAddMessage;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initial = name.trim().isEmpty ? '旅' : name.trim().substring(0, 1);
    final season = Season.of(now);
    final secondary = SeasonVisuals.secondary(season, c);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: SeasonVisuals.hero(season, c),
        ),
        border: Border.all(
          color: c.accent.withValues(alpha: c.isDark ? 0.24 : 0.34),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: secondary.withValues(alpha: c.isDark ? 0.22 : 0.18),
            blurRadius: 32,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -55,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondary.withValues(alpha: c.isDark ? 0.30 : 0.34),
                    secondary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -85,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.accent.withValues(alpha: c.isDark ? 0.18 : 0.22),
                    c.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
        Row(
          children: [
            CompassMark(
              key: LaunchTargets.homeCompass,
              size: 20,
              color: c.inkSoft,
              accent: c.accent,
              stroke: 3,
            ),
            const SizedBox(width: 9),
            Text('征途手札', style: AppText.eyebrow(color: c.inkSoft, size: 9.5)),
            const Spacer(),
            GestureDetector(
              onTap: onSettings,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.accent.withValues(alpha: 0.35), width: 1.2),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppText.serifStyle(size: 17, color: c.bg, height: 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '${monthEnglish(now)} ${two(now.day).padLeft(2, '0')} · ${weekdayLabel(now)}',
          style: AppText.eyebrow(color: c.inkSoft.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 9),
        Text(
          greetingFor(now, name),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.serifStyle(size: 29, color: c.ink, height: 1.28, letterSpacing: 1.1),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: secondary.withValues(alpha: 0.75), width: 1.8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“${quote.text}”',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppText.serifStyle(
                  size: 17,
                  weight: FontWeight.w400,
                  color: c.inkSoft,
                  height: 1.7,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              if (quote.author != '征途手札') ...[
                Text(
                  '— ${quote.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 10,
                    color: c.inkSoft.withValues(alpha: 0.78),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              GestureDetector(
                onTap: onAddMessage,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_comment_outlined, size: 12, color: secondary),
                      const SizedBox(width: 5),
                      Text(
                        '给未来的自己留句话',
                        style: AppText.sans(
                          size: 10.5,
                          weight: FontWeight.w500,
                          color: c.ink,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 11, color: secondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              '${seasonLabel(now)} · 第 ${dayOfYear(now)} 天',
              style: AppText.sans(size: 12, color: c.inkSoft, letterSpacing: 0.4),
            ),
            if (streak > 0) ...[
              const SizedBox(width: 10),
              Container(width: 3, height: 3, decoration: BoxDecoration(color: secondary, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Icon(Icons.local_fire_department_outlined, size: 13, color: secondary),
              const SizedBox(width: 3),
              Text(
                '连续手札 $streak 天',
                style: AppText.sans(size: 12, color: c.inkSoft, weight: FontWeight.w500),
              ),
            ],
          ],
        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.weather,
    required this.loading,
    required this.error,
    required this.onTap,
    required this.onRetry,
  });

  final WeatherSnapshot? weather;
  final bool loading;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = weather;
    final kind = w?.kind ?? WeatherKind.partly;
    final isDay = w?.isDay ?? true;
    final season = Season.of(DateTime.now());
    final colors = SeasonVisuals.weather(season, c, isDay: isDay);
    final ink = SeasonVisuals.weatherInk(colors, c);
    final soft = ink.withValues(alpha: 0.78);

    return GestureDetector(
      onTap: w == null ? onRetry : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(
            color: c.isDark ? Colors.transparent : c.line.withValues(alpha: 0.55),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: c.isDark ? 0.32 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
          ],
        ),
        child: w == null
            ? _WeatherPlaceholder(
                loading: loading,
                error: error,
                ink: ink,
                soft: soft,
                onRetry: onRetry,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.near_me_outlined, size: 13, color: soft),
                      const SizedBox(width: 5),
                      Text(
                        w.city,
                        style: AppText.sans(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: ink,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        loading ? '更新中…' : '更新于 ${timeHm(w.updatedAt)}',
                        style: AppText.sans(size: 10, color: soft),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: soft),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.temp.round().toString(),
                                  style: AppText.displayStyle(
                                    size: 66,
                                    color: ink,
                                    height: 0.95,
                                    letterSpacing: -2,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 2),
                                  child: Text(
                                    '°C',
                                    style: AppText.sans(
                                      size: 14,
                                      weight: FontWeight.w600,
                                      color: soft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              w.condition,
                              style: AppText.serifStyle(
                                size: 19,
                                color: ink,
                                weight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '体感 ${w.feelsLike.round()}° · 最高 ${w.tempMax.round()}° / 最低 ${w.tempMin.round()}°',
                              style: AppText.sans(size: 11, color: soft),
                            ),
                          ],
                        ),
                      ),
                      WeatherGlyph(
                        kind: kind,
                        size: 96,
                        color: ink.withValues(alpha: 0.92),
                        accent: isDay && kind != WeatherKind.clearNight
                            ? c.gold
                            : ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: c.isDark ? 0.08 : 0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates_outlined, size: 14, color: ink.withValues(alpha: 0.8)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            w.advice,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(
                              size: 11.5,
                              color: ink.withValues(alpha: 0.86),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _WeatherMeta(icon: Icons.water_drop_outlined, text: '${w.humidity}%', color: soft),
                      const SizedBox(width: 14),
                      _WeatherMeta(icon: Icons.air_rounded, text: '${w.wind.toStringAsFixed(0)} km/h', color: soft),
                      const SizedBox(width: 14),
                      _WeatherMeta(icon: Icons.umbrella_outlined, text: '${w.precipProb}%', color: soft),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _WeatherMeta extends StatelessWidget {
  const _WeatherMeta({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: AppText.sans(size: 10.5, color: color)),
      ],
    );
  }
}

class _WeatherPlaceholder extends StatelessWidget {
  const _WeatherPlaceholder({
    required this.loading,
    required this.error,
    required this.ink,
    required this.soft,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final Color ink;
  final Color soft;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me_outlined, size: 13, color: soft),
              const SizedBox(width: 5),
              Text('天气情报', style: AppText.sans(size: 12.5, weight: FontWeight.w600, color: ink)),
              const Spacer(),
              Text(loading ? '正在收集…' : '暂不可用', style: AppText.sans(size: 10, color: soft)),
            ],
          ),
          const Spacer(),
          if (loading)
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: inks(ink)),
                ),
                const SizedBox(width: 12),
                Text(
                  '正在向天空打听今天的消息',
                  style: AppText.serifStyle(size: 17, color: ink, weight: FontWeight.w500),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error ?? '天气站暂时联系不上',
                  style: AppText.serifStyle(size: 17, color: ink, weight: FontWeight.w500, height: 1.5),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: ink,
                    backgroundColor: ink.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text('再试一次', style: AppText.sans(size: 12, weight: FontWeight.w600, color: ink)),
                ),
              ],
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Color inks(Color color) => color.withValues(alpha: 0.8);
}

class _WeeklyEntry extends StatelessWidget {
  const _WeeklyEntry({
    required this.taskDone,
    required this.diaries,
    required this.expenses,
    required this.onTap,
  });

  final int taskDone;
  final int diaries;
  final double expenses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final secondary = SeasonVisuals.secondary(context.season, c);
    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          c.accentSoft.withValues(alpha: c.isDark ? 0.72 : 0.92),
          secondary.withValues(alpha: c.isDark ? 0.18 : 0.16),
        ],
      ),
      borderColor: c.accent.withValues(alpha: 0.18),
      elevated: false,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: c.accent),
                    const SizedBox(width: 5),
                    Eyebrow('Weekly Review', color: c.accent),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '这一周，你走了多远',
                  style: AppText.serifStyle(size: 17, color: c.ink, letterSpacing: 0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  '完成任务 $taskDone · 手札 $diaries · 支出 ${money(expenses)}',
                  style: AppText.sans(size: 10, color: c.inkSoft.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: c.accent.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.arrow_forward_rounded, size: 18, color: c.accent),
          ),
        ],
      ),
    );
  }
}

class _HomeTaskRow extends StatelessWidget {
  const _HomeTaskRow({required this.task, required this.onToggle, required this.onEdit});

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = task.type == TaskType.main ? c.accent : c.moss;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedCheck(checked: task.done, onTap: onToggle),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 14.5,
                      weight: FontWeight.w500,
                      color: task.done ? c.muted : c.ink,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ).copyWith(decoration: task.done ? TextDecoration.lineThrough : null,
                        decorationColor: c.muted),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      TagChip(label: task.type.label, color: tone, dense: true),
                      const SizedBox(width: 5),
                      if (task.dueDate != null)
                        Text(
                          dueLabel(task.dueDate),
                          style: AppText.sans(
                            size: 10,
                            color: task.isOverdue ? c.terra : c.muted,
                            weight: task.isOverdue ? FontWeight.w600 : FontWeight.w400,
                          ),
                        )
                      else if (task.note.trim().isNotEmpty)
                        Expanded(
                          child: Text(
                            task.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(size: 10, color: c.muted),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: c.muted.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _EmptyTaskCard extends StatelessWidget {
  const _EmptyTaskCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PaperCard(
      onTap: onAdd,
      padding: const EdgeInsets.all(18),
      elevated: false,
      color: c.surface.withValues(alpha: 0.55),
      child: Row(
        children: [
          IconBadge(icon: Icons.explore_outlined, color: c.moss, size: 42, iconSize: 19),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今天还没有排队的任务', style: AppText.serifStyle(size: 15, color: c.ink)),
                const SizedBox(height: 4),
                Text('给自己安排一条小小的支线吧', style: AppText.sans(size: 11.5, color: c.muted)),
              ],
            ),
          ),
          Icon(Icons.add_circle_outline_rounded, size: 20, color: c.accent),
        ],
      ),
    );
  }
}

class _DiaryPromptCard extends StatelessWidget {
  const _DiaryPromptCard({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PaperCard(
      onTap: onWrite,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      elevated: false,
      color: c.surface.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_outlined, size: 17, color: c.accent),
              const SizedBox(width: 7),
              Text('PAGE OF THE DAY', style: AppText.eyebrow(color: c.muted, size: 9)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '今天，发生了什么值得记住的小事？',
            style: AppText.serifStyle(size: 18, color: c.ink, weight: FontWeight.w500, height: 1.6),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('写下第一行', style: AppText.sans(size: 12, weight: FontWeight.w600, color: c.accent)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 13, color: c.accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiaryPreviewCard extends StatelessWidget {
  const _DiaryPreviewCard({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (entry.mood != null) ...[
                Text(entry.mood!.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(entry.mood!.label, style: AppText.sans(size: 10.5, color: c.muted)),
                const SizedBox(width: 8),
              ],
              Text('${entry.charCount} 字', style: AppText.sans(size: 10.5, color: c.muted)),
              const Spacer(),
              Text(timeHm(entry.updatedAt), style: AppText.sans(size: 10, color: c.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.serifStyle(size: 19, color: c.ink, height: 1.5),
          ),
          if (entry.content.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              entry.excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 12.5, color: c.inkSoft, height: 1.8),
            ),
          ],
          if (entry.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  for (final path in entry.images.take(4))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(path),
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 58,
                            height: 58,
                            color: c.sunken,
                            child: Icon(Icons.broken_image_outlined, size: 16, color: c.muted),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.total,
    required this.count,
    required this.monthTotal,
    required this.series,
    required this.onTap,
    required this.onAdd,
  });

  final double total;
  final int count;
  final double monthTotal;
  final List<double> series;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = series.fold<double>(0, (m, v) => v > m ? v : m);
    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('今天', style: AppText.sans(size: 10.5, color: c.muted)),
                    const SizedBox(width: 6),
                    Text('${count} 笔', style: AppText.sans(size: 10.5, color: c.muted.withValues(alpha: 0.7))),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  money(total),
                  style: AppText.displayStyle(size: 32, color: c.ink, letterSpacing: -0.5),
                ),
                const SizedBox(height: 5),
                Text(
                  '本月 ${money(monthTotal)}',
                  style: AppText.sans(size: 11, color: c.muted),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onAdd,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: c.accent),
                      const SizedBox(width: 3),
                      Text('记一笔', style: AppText.sans(size: 11.5, weight: FontWeight.w600, color: c.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 128,
            height: 76,
            child: CustomPaint(
              painter: _SparklinePainter(
                values: series,
                maxValue: maxValue,
                color: c.accent,
                base: c.line,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.maxValue,
    required this.color,
    required this.base,
  });

  final List<double> values;
  final double maxValue;
  final Color color;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final peak = maxValue <= 0 ? 1.0 : maxValue;
    final gap = size.width / (values.length * 1.8);
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;
    final baseline = size.height;
    for (var i = 0; i < values.length; i++) {
      final ratio = (values[i] / peak).clamp(0.0, 1.0);
      final height = ratio * (size.height - 6);
      final active = i == values.length - 1;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (barWidth + gap), baseline - height - 2, barWidth, height.clamp(3, size.height)),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = active ? color : base.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.maxValue != maxValue || old.color != color;
}
