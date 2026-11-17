import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';

Future<void> showHabitEditor(BuildContext context, {Habit? habit}) {
  return showAppSheet<void>(context, HabitEditorSheet(habit: habit));
}

class HabitEditorSheet extends StatefulWidget {
  const HabitEditorSheet({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<HabitEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late TaskType _type;
  late TaskPriority _priority;
  late DateTime _startDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _titleController = TextEditingController(text: habit?.title ?? '');
    _noteController = TextEditingController(text: habit?.note ?? '');
    _type = habit?.type ?? TaskType.main;
    _priority = habit?.priority ?? TaskPriority.medium;
    _startDate = dateOnly(habit?.startDate ?? today());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: today(),
      helpText: '从哪一天开始？',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() => _startDate = dateOnly(picked));
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppSnack(context, '先给这个长期任务起个名字');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final old = widget.habit;
    final now = DateTime.now();
    final habit = Habit(
      id: old?.id,
      title: title,
      note: _noteController.text.trim(),
      type: _type,
      priority: _priority,
      startDate: _startDate,
      archived: old?.archived ?? false,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await context.read<AppStore>().saveHabit(habit);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, '长期任务没有存好，再试一次');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEditing = widget.habit != null;
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: isEditing ? '编辑每日打卡' : '新的每日打卡',
            subtitle: '每天出现一次，打卡会留下时间和次数',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            autofocus: !isEditing,
            textInputAction: TextInputAction.next,
            style: AppText.serifStyle(size: 19, color: c.ink),
            decoration: fieldDecoration(context, hint: '比如：健身、学日语、读书'),
          ),
          const SizedBox(height: 18),
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
          _FieldLabel('开始日期'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickStartDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available_outlined, size: 17, color: c.accent),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${fullDateLabel(_startDate)} 开始',
                      style: AppText.sans(size: 13, color: c.inkSoft),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 17, color: c.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: c.accentSoft.withValues(alpha: c.isDark ? 0.42 : 0.62),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.repeat_rounded, size: 15, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '每天都会出现在「每日打卡」里；打卡后可以撤销，历史不会因为新的一天开始而消失。',
                    style: AppText.sans(
                      size: 11,
                      color: c.inkSoft,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
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
            decoration: fieldDecoration(context, hint: '为什么想做这件事？（可选）'),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: isEditing ? '保存修改' : '开始打卡',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _save,
          ),
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
