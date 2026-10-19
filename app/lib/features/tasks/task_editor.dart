import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';

Future<void> showTaskEditor(BuildContext context, {TaskItem? task}) {
  return showAppSheet<void>(context, TaskEditorSheet(task: task));
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.task});

  final TaskItem? task;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late TaskType _type;
  late TaskPriority _priority;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _noteController = TextEditingController(text: task?.note ?? '');
    _type = task?.type ?? TaskType.main;
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '截止到哪一天？',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = dateOnly(picked));
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppSnack(context, '先给任务起个名字');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final store = context.read<AppStore>();
    final old = widget.task;
    final task = TaskItem(
      id: old?.id,
      title: title,
      note: _noteController.text.trim(),
      type: _type,
      priority: _priority,
      dueDate: _dueDate,
      done: old?.done ?? false,
      completedAt: old?.completedAt,
      createdAt: old?.createdAt ?? DateTime.now(),
    );
    try {
      await store.saveTask(task);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, '任务没有存好，再试一次');
    }
  }

  Future<void> _delete() async {
    final task = widget.task;
    if (task == null) return;
    final confirmed = await confirmAction(
      context,
      title: '放弃这条任务？',
      message: '「${task.title}」会被移出你的清单。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<AppStore>().deleteTask(task);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEditing = widget.task != null;
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: isEditing ? '编辑任务' : '新的任务',
            subtitle: '主线是方向，支线是风景',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            autofocus: !isEditing,
            textInputAction: TextInputAction.next,
            style: AppText.serifStyle(size: 19, color: c.ink),
            decoration: fieldDecoration(context, hint: '要完成什么？'),
          ),
          const SizedBox(height: 20),
          _FieldLabel('类型'),
          const SizedBox(height: 8),
          PillSelector(
            options: const ['主线', '支线'],
            selected: _type == TaskType.main ? 0 : 1,
            onChanged: (index) =>
                setState(() => _type = index == 0 ? TaskType.main : TaskType.side),
            activeColors: [c.accent, c.moss],
          ),
          const SizedBox(height: 16),
          _FieldLabel('优先级'),
          const SizedBox(height: 8),
          PillSelector(
            options: const ['高', '中', '低'],
            selected: _priority.rank,
            onChanged: (index) => setState(() => _priority = TaskPriority.values[index]),
            activeColors: [c.terra, c.accent, c.moss],
          ),
          const SizedBox(height: 16),
          _FieldLabel('截止日期'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDueDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, size: 17, color: c.accent),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _dueDate == null ? '不设截止日期' : fullDateLabel(_dueDate!),
                      style: AppText.sans(
                        size: 13,
                        color: _dueDate == null ? c.muted : c.inkSoft,
                      ),
                    ),
                  ),
                  if (_dueDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: Icon(Icons.close_rounded, size: 16, color: c.muted),
                    )
                  else
                    Icon(Icons.expand_more_rounded, size: 17, color: c.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('备注'),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            style: AppText.sans(size: 13.5, color: c.ink, height: 1.6),
            decoration: fieldDecoration(context, hint: '补充一点细节（可选）'),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: isEditing ? '保存修改' : '加入清单',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _save,
          ),
          if (isEditing) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _delete,
                child: Text(
                  '删除任务',
                  style: AppText.sans(size: 12.5, color: c.terra),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      text,
      style: AppText.sans(
        size: 10.5,
        weight: FontWeight.w600,
        color: c.muted,
        letterSpacing: 1.2,
      ),
    );
  }
}
