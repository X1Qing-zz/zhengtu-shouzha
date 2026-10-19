import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/compass_mark.dart';
import 'diary_editor.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final diaries = store.diaries;
    final todayEntry = store.diaryForDay(today());

    final groups = <String, List<DiaryEntry>>{};
    for (final entry in diaries) {
      final key = '${entry.date.year}-${two(entry.date.month)}';
      groups.putIfAbsent(key, () => []).add(entry);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(context, todayEntry),
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          elevation: 3,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(
            '写手札',
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('Journal · 手札', color: c.accent),
                      const SizedBox(height: 9),
                      Text('冒险手札', style: AppText.serifStyle(size: 32, color: c.ink, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                        diaries.isEmpty
                            ? '把日子写下来，它就有了形状。'
                            : '已写下 ${diaries.length} 篇 · 连续 ${store.diaryStreakCount} 天',
                        style: AppText.sans(size: 12, color: c.muted, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
                CompassMark(size: 54, color: c.ink, accent: c.accent, stroke: 1.8),
              ],
            ),
            const SizedBox(height: 22),
            if (todayEntry == null)
              _TodayPrompt(onTap: () => _openEditor(context, null))
            else
              _TodayWritten(entry: todayEntry, onTap: () => _openEditor(context, todayEntry)),
            const SizedBox(height: 8),
            if (diaries.isEmpty)
              EmptyState(
                icon: Icons.auto_stories_outlined,
                title: '第一页还在等你',
                message: '不必写得漂亮，只要真实。\n今天的一阵风、一顿饭、一个念头，都可以。',
                actionLabel: '写下第一篇',
                onAction: () => _openEditor(context, null),
              )
            else
              for (final group in groups.entries) ...[
                _MonthHeader(
                  label: _monthLabel(group.key),
                  count: group.value.length,
                ),
                for (final entry in group.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DiaryCard(
                      entry: entry,
                      onTap: () => _openEditor(context, entry),
                      onDelete: () => _delete(context, store, entry),
                    ),
                  ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    return '${parts[0]} 年 ${int.parse(parts[1])} 月';
  }

  void _openEditor(BuildContext context, DiaryEntry? entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiaryEditorPage(entry: entry, initialDate: entry?.date ?? today()),
      ),
    );
  }

  Future<void> _delete(BuildContext context, AppStore store, DiaryEntry entry) async {
    final confirmed = await confirmAction(
      context,
      title: '要撕掉这一页吗？',
      message: '「${entry.displayTitle}」和它附带的照片都会被删除。',
      confirmLabel: '撕掉',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await store.deleteDiary(entry);
    if (context.mounted) showAppSnack(context, '这一页已经收进风里');
  }
}

class _TodayPrompt extends StatelessWidget {
  const _TodayPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: c.accentSoft.withValues(alpha: c.isDark ? 0.28 : 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.accent.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 20, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今天的手札还没落笔',
                    style: AppText.serifStyle(size: 15, color: c.ink, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${dayTitle(today())} · ${weekdayLabel(today())}',
                    style: AppText.sans(size: 10.5, color: c.muted),
                  ),
                ],
              ),
            ),
            Text('写下来', style: AppText.sans(size: 11.5, weight: FontWeight.w600, color: c.accent)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 13, color: c.accent),
          ],
        ),
      ),
    );
  }
}

class _TodayWritten extends StatelessWidget {
  const _TodayWritten({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: c.mossSoft.withValues(alpha: c.isDark ? 0.5 : 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.moss.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 19, color: c.moss),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                '今天已记录 ${entry.charCount} 字${entry.images.isEmpty ? '' : ' · ${entry.images.length} 张照片'}',
                style: AppText.sans(size: 11.5, color: c.inkSoft),
              ),
            ),
            Text('继续写', style: AppText.sans(size: 11.5, weight: FontWeight.w600, color: c.moss)),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Row(
        children: [
          Text(label, style: AppText.serifStyle(size: 19, color: c.ink, letterSpacing: 1)),
          const SizedBox(width: 10),
          Text('$count 篇', style: AppText.sans(size: 10, color: c.muted)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 0.8, color: c.line.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({required this.entry, required this.onTap, required this.onDelete});

  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  entry.date.day.toString().padLeft(2, '0'),
                  style: AppText.displayStyle(size: 31, color: c.accent, height: 1),
                ),
                const SizedBox(height: 3),
                Text(
                  weekdayLabel(entry.date),
                  style: AppText.sans(size: 9.5, color: c.muted),
                ),
                const SizedBox(height: 10),
                if (entry.mood != null)
                  Text(entry.mood!.emoji, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Container(
            width: 0.8,
            height: 68,
            margin: const EdgeInsets.only(right: 14),
            color: c.line.withValues(alpha: 0.9),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.serifStyle(size: 17, color: c.ink, height: 1.4),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 17,
                        icon: Icon(Icons.more_horiz_rounded, color: c.muted.withValues(alpha: 0.8)),
                        color: c.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: (value) {
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 17, color: c.terra),
                                const SizedBox(width: 8),
                                Text('删除这一页', style: AppText.sans(size: 13, color: c.terra)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (entry.content.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 12, color: c.inkSoft, height: 1.75),
                  ),
                ],
                if (entry.images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        for (final path in entry.images.take(3))
                          Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(
                                File(path),
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color: c.sunken,
                                  child: Icon(Icons.broken_image_outlined, size: 14, color: c.muted),
                                ),
                              ),
                            ),
                          ),
                        if (entry.images.length > 3)
                          Text('+${entry.images.length - 3}', style: AppText.sans(size: 11, color: c.muted)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  '${timeHm(entry.updatedAt)} · ${entry.charCount} 字',
                  style: AppText.sans(size: 9.5, color: c.muted.withValues(alpha: 0.85), letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
