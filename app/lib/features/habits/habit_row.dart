import 'package:flutter/material.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/habit_stats.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

class HabitRow extends StatelessWidget {
  const HabitRow({
    super.key,
    required this.habit,
    required this.checkin,
    required this.stats,
    required this.onToggle,
    required this.onTap,
    this.compact = false,
  });

  final Habit habit;
  final HabitCheckin? checkin;
  final HabitStats stats;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final checked = checkin != null;
    final tone = habit.type == TaskType.main ? c.accent : c.moss;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 5 : 9),
        child: Row(
          children: [
            AnimatedCheck(
              checked: checked,
              onTap: onToggle,
              size: 23,
              color: c.moss,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: compact ? 13.5 : 14.5,
                      weight: FontWeight.w500,
                      color: c.ink,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 7,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (!compact)
                        TagChip(
                          label: habit.type.label,
                          color: tone,
                          dense: true,
                          icon: habit.type.icon,
                        ),
                      Text(
                        stats.currentStreak > 0
                            ? '连续 ${stats.currentStreak} 天'
                            : '今天开始',
                        style: AppText.sans(
                          size: 10,
                          weight: FontWeight.w500,
                          color: stats.currentStreak > 0 ? c.moss : c.muted,
                        ),
                      ),
                      Text(
                        '累计 ${stats.total} 次',
                        style: AppText.sans(size: 10, color: c.muted),
                      ),
                      if (checked)
                        Text(
                          '今天 ${timeHm(checkin!.checkedAt)}',
                          style: AppText.sans(
                            size: 10,
                            weight: FontWeight.w500,
                            color: c.accent,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: c.muted.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}
