import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';

Future<void> showExpenseEditor(BuildContext context, {Expense? expense}) {
  return showAppSheet<void>(context, ExpenseEditorSheet(expense: expense));
}

class ExpenseEditorSheet extends StatefulWidget {
  const ExpenseEditorSheet({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseEditorSheet> createState() => _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends State<ExpenseEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _category;
  late bool _isIncome;
  late DateTime _spentAt;
  late DateTime _createdAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _isIncome = expense?.isIncome ?? false;
    _amountController = TextEditingController(
      text: expense == null ? '' : amountInput(expense.amount),
    );
    _noteController = TextEditingController(text: expense?.note ?? '');
    _category = expense?.category ?? categoriesFor(income: _isIncome).first.name;
    _spentAt = expense?.spentAt ?? DateTime.now();
    _createdAt = expense?.createdAt ?? DateTime.now();
  }

  void _setIncome(bool value) {
    if (_isIncome == value) return;
    setState(() {
      _isIncome = value;
      final categories = categoriesFor(income: value);
      if (!categories.any((category) => category.name == _category)) {
        _category = categories.first.name;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2000),
      lastDate: today(),
      helpText: '这笔花在了哪天？',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _spentAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _spentAt.hour,
        _spentAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_spentAt),
      helpText: '选择时间',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _spentAt = DateTime(
        _spentAt.year,
        _spentAt.month,
        _spentAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      showAppSnack(context, '先写下这笔的金额');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final store = context.read<AppStore>();
    final expense = Expense(
      id: widget.expense?.id,
      amount: double.parse(amount.toStringAsFixed(2)),
      category: _category,
      note: _noteController.text.trim(),
      spentAt: _spentAt,
      createdAt: _createdAt,
      isIncome: _isIncome,
    );
    try {
      await store.saveExpense(expense);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, '记账没有成功，再试一次');
    }
  }

  Future<void> _delete() async {
    final expense = widget.expense;
    if (expense == null) return;
    final confirmed = await confirmAction(
      context,
      title: '删掉这笔记录？',
      message: '${expense.category} · ${money(expense.amount)} 会从账本里消失。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<AppStore>().deleteExpense(expense);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEditing = widget.expense != null;
    final categories = categoriesFor(income: _isIncome);
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: isEditing ? '编辑这笔' : '记一笔',
            subtitle: '记录每一笔进出，日子更有数',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _EntryTypeTab(
                  label: '支出',
                  icon: Icons.north_east_rounded,
                  color: c.terra,
                  selected: !_isIncome,
                  onTap: () => _setIncome(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EntryTypeTab(
                  label: '收入',
                  icon: Icons.south_west_rounded,
                  color: c.moss,
                  selected: _isIncome,
                  onTap: () => _setIncome(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 9, right: 4),
                child: Text(
                  '¥',
                  style: AppText.displayStyle(size: 25, color: c.muted, height: 1),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  autofocus: !isEditing,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text;
                      if (text.isEmpty) return newValue;
                      if (RegExp(r'^\d{0,8}(\.\d{0,2})?$').hasMatch(text)) {
                        return newValue;
                      }
                      return oldValue;
                    }),
                  ],
                  style: AppText.displayStyle(size: 46, color: c.ink, height: 1.05),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: '0.00',
                    hintStyle: AppText.displayStyle(
                      size: 46,
                      color: c.muted.withValues(alpha: 0.35),
                      height: 1.05,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 0.8, color: c.line),
          const SizedBox(height: 18),
          Text(
            '分类',
            style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: c.muted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = category.name == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = category.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? category.color.withValues(alpha: c.isDark ? 0.22 : 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: selected ? category.color.withValues(alpha: 0.5) : c.line.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selected ? category.color : category.color.withValues(alpha: 0.13),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          size: 16,
                          color: selected ? Colors.white : category.color,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category.name,
                        style: AppText.sans(
                          size: 10,
                          weight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? c.ink : c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: AppText.sans(size: 13.5, color: c.ink),
            decoration: fieldDecoration(
              context,
              hint: _isIncome ? '这笔收入来自哪里？（可选）' : '买了什么？（可选）',
              prefix: Icon(Icons.edit_outlined, size: 17, color: c.muted),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateTimeButton(
                  icon: Icons.event_outlined,
                  label: '${_spentAt.month} 月 ${_spentAt.day} 日',
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateTimeButton(
                  icon: Icons.schedule_rounded,
                  label: timeHm(_spentAt),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: isEditing ? '保存修改' : '记下这笔',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _save,
          ),
          if (isEditing) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _delete,
                child: Text('删除这笔', style: AppText.sans(size: 12.5, color: c.terra)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryTypeTab extends StatelessWidget {
  const _EntryTypeTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: c.isDark ? 0.22 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.45) : c.line,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? color : c.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.sans(
                size: 12.5,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? c.ink : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c.accent),
            const SizedBox(width: 7),
            Text(label, style: AppText.sans(size: 12.5, color: c.inkSoft)),
            const Spacer(),
            Icon(Icons.expand_more_rounded, size: 15, color: c.muted),
          ],
        ),
      ),
    );
  }
}
