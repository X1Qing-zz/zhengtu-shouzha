import 'package:flutter/material.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/habit_stats.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

Future<DateTime?> showHabitMakeupSheet(
  BuildContext context, {
  required Habit habit,
  required Set<String> checkedDates,
  DateTime? initialDate,
}) {
  return showAppSheet<DateTime>(
    context,
    HabitMakeupSheet(
      habit: habit,
      checkedDates: checkedDates,
      initialDate: initialDate,
    ),
  );
}

class HabitMakeupSheet extends StatefulWidget {
  const HabitMakeupSheet({
    super.key,
    required this.habit,
    required this.checkedDates,
    this.initialDate,
  });

  final Habit habit;
  final Set<String> checkedDates;
  final DateTime? initialDate;

  @override
  State<HabitMakeupSheet> createState() => _HabitMakeupSheetState();
}

class _HabitMakeupSheetState extends State<HabitMakeupSheet> {
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _firstDate = dateOnly(widget.habit.startDate);
    _lastDate = today().subtract(const Duration(days: 1));
    _selected = _pickInitialDate();
  }

  bool get _hasRange => !_lastDate.isBefore(_firstDate);

  bool _isChecked(DateTime day) => widget.checkedDates.contains(ymd(day));

  bool _canSelect(DateTime day) {
    final target = dateOnly(day);
    return isHabitMakeupDate(target, startDate: _firstDate) &&
        !_isChecked(target);
  }

  DateTime? _pickInitialDate() {
    if (!_hasRange) return null;
    final requested = widget.initialDate == null
        ? _lastDate
        : dateOnly(widget.initialDate!);
    var candidate = requested.isAfter(_lastDate)
        ? _lastDate
        : (requested.isBefore(_firstDate) ? _firstDate : requested);
    while (!candidate.isBefore(_firstDate)) {
      if (_canSelect(candidate)) return candidate;
      candidate = candidate.subtract(const Duration(days: 1));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: '补签一天',
            subtitle: '把漏掉的那天补回来；只补日期，不会改动今天的打卡',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
          if (_selected == null)
            _MakeupEmptyState(hasRange: _hasRange, startDate: _firstDate)
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: c.accentSoft.withValues(alpha: c.isDark ? 0.55 : 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: c.accent.withValues(alpha: 0.24),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 19,
                    color: c.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullDateLabel(_selected!),
                          style: AppText.serifStyle(
                            size: 15,
                            color: c.ink,
                            weight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '补签会保留原来的日期，记录时间显示为现在。',
                          style: AppText.sans(size: 10.5, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            CalendarDatePicker(
              initialDate: _selected!,
              firstDate: _firstDate,
              lastDate: _lastDate,
              currentDate: today(),
              selectableDayPredicate: _canSelect,
              onDateChanged: (value) {
                setState(() => _selected = dateOnly(value));
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_selected),
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text('补上这一天'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.ink,
                  foregroundColor: c.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MakeupEmptyState extends StatelessWidget {
  const _MakeupEmptyState({required this.hasRange, required this.startDate});

  final bool hasRange;
  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      decoration: BoxDecoration(
        color: c.sunken.withValues(alpha: c.isDark ? 0.55 : 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 28, color: c.muted),
          const SizedBox(height: 12),
          Text(
            hasRange ? '没有漏掉的日子' : '还没有可补签的日期',
            style: AppText.serifStyle(size: 17, color: c.ink),
          ),
          const SizedBox(height: 7),
          Text(
            hasRange
                ? '从 ${dayTitle(startDate)} 开始，每一天都打过卡了。'
                : '这个习惯今天才开始，明天之后再来补签。',
            textAlign: TextAlign.center,
            style: AppText.sans(size: 11.5, color: c.muted, height: 1.7),
          ),
        ],
      ),
    );
  }
}
