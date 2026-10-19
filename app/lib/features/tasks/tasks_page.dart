import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import 'task_editor.dart';

enum _StatusFilter { open, done, all }

enum _TypeFilter { all, main, side }

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  _StatusFilter _status = _StatusFilter.open;
  _TypeFilter _type = _TypeFilter.all;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final items = store.tasks.where((task) {
      final typeOk = switch (_type) {
        _TypeFilter.all => true,
        _TypeFilter.main => task.type == TaskType.main,
        _TypeFilter.side => task.type == TaskType.side,
      };
      final statusOk = switch (_status) {
        _StatusFilter.open => !task.done,
        _StatusFilter.done => task.done,
        _StatusFilter.all => true,
      };
      return typeOk && statusOk;
    }).toList();

    final groups = _buildGroups(items, store);
    final todayTasks = store.todayTasks;
    final todayRatio = todayTasks.isEmpty
        ? 0.0
        : todayTasks.where((t) => t.done).length / todayTasks.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: FloatingActionButton.extended(
          onPressed: () => showTaskEditor(context),
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            '新任务',
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
            Eyebrow('Quests · 任务', color: c.accent),
            const SizedBox(height: 9),
            Text('主线与支线', style: AppText.serifStyle(size: 32, color: c.ink, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(
              '待完成 ${store.openTaskCount} 项 · 今日完成 ${store.todayDoneCount} 项',
              style: AppText.sans(size: 12, color: c.muted, letterSpacing: 0.3),
            ),
            const SizedBox(height: 22),
            PaperCard(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatBlock(
                          value: '${store.todayDoneCount}',
                          label: '今日完成',
                          tone: c.moss,
                        ),
                      ),
                      Container(width: 0.8, height: 34, color: c.line),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: StatBlock(
                            value: '${store.openTaskCount}',
                            label: '待完成',
                            tone: c.ink,
                          ),
                        ),
                      ),
                      Container(width: 0.8, height: 34, color: c.line),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: StatBlock(
                            value: '${store.overdueCount}',
                            label: '已逾期',
                            tone: store.overdueCount > 0 ? c.terra : c.ink,
                          ),
                        ),
                      ),
                      Container(width: 0.8, height: 34, color: c.line),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: StatBlock(
                            value: '${store.weekDoneCount}',
                            label: '本周完成',
                            tone: c.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('今日进度', style: AppText.sans(size: 10, color: c.muted)),
                      const Spacer(),
                      Text(
                        '${(todayRatio * 100).round()}%',
                        style: AppText.sans(size: 10, weight: FontWeight.w600, color: c.moss),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppProgressBar(value: todayRatio, height: 5, color: c.moss),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PillSelector(
              options: const ['进行中', '已完成', '全部'],
              selected: _status.index,
              onChanged: (index) => setState(() => _status = _StatusFilter.values[index]),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Text('筛选', style: AppText.sans(size: 10, color: c.muted)),
                ),
                Expanded(
                  child: PillSelector(
                    dense: true,
                    options: const ['全部', '主线', '支线'],
                    selected: _type.index,
                    onChanged: (index) => setState(() => _type = _TypeFilter.values[index]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (items.isEmpty)
              EmptyState(
                icon: Icons.task_alt_rounded,
                title: _status == _StatusFilter.done ? '还没有完成的任务' : '清单暂时是空的',
                message: _status == _StatusFilter.done
                    ? '完成一条任务，它会出现在这里。'
                    : '主线给你方向，支线给你风景。\n先写下一个想完成的小目标吧。',
                actionLabel: _status == _StatusFilter.done ? null : '添加任务',
                onAction: () => showTaskEditor(context),
              )
            else
              for (final group in groups) ...[
                _GroupHeader(label: group.label, count: group.items.length, color: group.color),
                const SizedBox(height: 8),
                PaperCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Column(
                    children: [
                      for (var i = 0; i < group.items.length; i++) ...[
                        _TaskRow(
                          task: group.items[i],
                          onToggle: () => _toggle(context, store, group.items[i]),
                          onEdit: () => showTaskEditor(context, task: group.items[i]),
                        ),
                        if (i != group.items.length - 1)
                          Divider(height: 1, color: c.line.withValues(alpha: 0.55)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, AppStore store, TaskItem task) async {
    HapticFeedback.selectionClick();
    final wasDone = task.done;
    await store.toggleTask(task);
    if (!context.mounted) return;
    if (!wasDone) {
      showAppSnack(
        context,
        '完成了「${task.title}」',
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => store.toggleTask(
            task.copyWith(done: true, completedAt: DateTime.now()),
          ),
        ),
      );
    }
  }

  List<_TaskGroup> _buildGroups(List<TaskItem> items, AppStore store) {
    final c = context.colors;
    if (_status == _StatusFilter.done) {
      final done = List<TaskItem>.of(items)
        ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
      return done.isEmpty
          ? const []
          : [_TaskGroup(label: '已完成', color: c.moss, items: done)];
    }

    final open = items.where((t) => !t.done).toList();
    final groups = <_TaskGroup>[];
    void addGroup(String label, Color color, List<TaskItem> list) {
      if (list.isEmpty) return;
      list.sort((a, b) {
        final byPriority = a.priority.rank.compareTo(b.priority.rank);
        if (byPriority != 0) return byPriority;
        return (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999));
      });
      groups.add(_TaskGroup(label: label, color: color, items: list));
    }

    addGroup('已逾期', c.terra, open.where((t) => t.isOverdue).toList());
    addGroup('今天', c.accent, open.where((t) => !t.isOverdue && t.isDueToday).toList());
    addGroup(
      '接下来',
      c.sky,
      open
          .where((t) =>
              !t.isOverdue &&
              !t.isDueToday &&
              t.dueDate != null &&
              t.dueDate!.isAfter(today()))
          .toList(),
    );
    addGroup('无期限', c.muted, open.where((t) => t.dueDate == null).toList());

    if (_status == _StatusFilter.all) {
      final done = items.where((t) => t.done).toList()
        ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
      if (done.isNotEmpty) {
        groups.add(_TaskGroup(label: '已完成', color: c.moss, items: done));
      }
    }
    return groups;
  }
}

class _TaskGroup {
  _TaskGroup({required this.label, required this.color, required this.items});

  final String label;
  final Color color;
  final List<TaskItem> items;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppText.sans(size: 11, weight: FontWeight.w600, color: color, letterSpacing: 1.2),
        ),
        const SizedBox(width: 6),
        Text('$count', style: AppText.sans(size: 10, color: c.muted)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 0.8, color: c.line.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onToggle, required this.onEdit});

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final priorityColor = switch (task.priority) {
      TaskPriority.high => c.terra,
      TaskPriority.medium => c.gold,
      TaskPriority.low => c.moss,
    };
    final typeColor = task.type == TaskType.main ? c.accent : c.moss;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 28,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: task.done ? c.line : priorityColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedCheck(checked: task.done, onTap: onToggle, size: 23),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 14.5,
                      weight: FontWeight.w500,
                      color: task.done ? c.muted : c.ink,
                      height: 1.45,
                      letterSpacing: 0.15,
                    ).copyWith(
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      decorationColor: c.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TagChip(label: task.type.label, color: typeColor, dense: true, icon: task.type.icon),
                      if (task.dueDate != null)
                        Text(
                          task.done && task.completedAt != null
                              ? '${timeHm(task.completedAt!)} 完成'
                              : dueLabel(task.dueDate),
                          style: AppText.sans(
                            size: 10,
                            color: task.isOverdue ? c.terra : c.muted,
                            weight: task.isOverdue ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      if (task.note.trim().isNotEmpty)
                        Text(
                          task.note.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(size: 10, color: c.muted.withValues(alpha: 0.9)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 17, color: c.muted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
