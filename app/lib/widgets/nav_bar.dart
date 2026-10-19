import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/season_visuals.dart';
import '../core/theme.dart';

class NavDestination {
  const NavDestination(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const List<NavDestination> kNavDestinations = [
  NavDestination(Icons.wb_twilight_outlined, Icons.wb_twilight_rounded, '今日'),
  NavDestination(Icons.checklist_outlined, Icons.checklist_rounded, '任务'),
  NavDestination(Icons.auto_stories_outlined, Icons.auto_stories_rounded, '手札'),
  NavDestination(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, '账本'),
  NavDestination(Icons.calendar_month_outlined, Icons.calendar_month_rounded, '日历'),
];

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.index,
    required this.onTap,
  });

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final secondary = SeasonVisuals.secondary(context.season, c);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: c.isDark ? 0.82 : 0.86),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.line.withValues(alpha: 0.8), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: c.shadow.withValues(alpha: c.isDark ? 0.4 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: List.generate(kNavDestinations.length, (i) {
                final destination = kNavDestinations[i];
                final active = i == index;
                return Expanded(
                  child: Semantics(
                    selected: active,
                    button: true,
                    label: destination.label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          gradient: active
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    c.accent.withValues(alpha: c.isDark ? 0.26 : 0.22),
                                    secondary.withValues(alpha: c.isDark ? 0.20 : 0.18),
                                  ],
                                )
                              : null,
                          color: active ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: active
                                ? c.accent.withValues(alpha: 0.22)
                                : Colors.transparent,
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: active ? 1.06 : 1,
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                active ? destination.activeIcon : destination.icon,
                                size: 21,
                                color: active ? secondary : c.muted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              destination.label,
                              style: AppText.sans(
                                size: 10,
                                weight: active ? FontWeight.w600 : FontWeight.w500,
                                color: active ? c.ink : c.muted,
                                height: 1.2,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
