import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_store.dart';
import '../../widgets/compass_mark.dart';
import '../onboarding.dart';
import '../shell.dart';

/// A short opening scene: the compass fades in, the needle turns to south,
/// then the emblem settles into the top-left corner and the app appears.
class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    if (_controller.value >= 1) return;
    _controller.animateTo(
      1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final page = store.onboarded ? const RootShell() : const OnboardingPage();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.value >= 1) return page;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: _LaunchScene(progress: _controller.value),
        );
      },
    );
  }
}

class _LaunchScene extends StatelessWidget {
  const _LaunchScene({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = progress.clamp(0.0, 1.0);

    final fade = Curves.easeOutCubic.transform((p / 0.16).clamp(0.0, 1.0));
    final turnT = Curves.easeInOutCubic.transform(((p - 0.03) / 0.52).clamp(0.0, 1.0));
    final moveT = Curves.easeInOutCubic.transform(((p - 0.58) / 0.30).clamp(0.0, 1.0));
    final textFade = (1 - ((p - 0.48) / 0.14)).clamp(0.0, 1.0);
    final skipFade = (1 - ((p - 0.64) / 0.16)).clamp(0.0, 1.0) * 0.7;

    final alignment = Alignment.lerp(Alignment.center, Alignment.topLeft, moveT)!;
    final scale = 1 - 0.78 * moveT;
    final angle = turnT * math.pi * 3; // 1.5 turns, ending with north pointing south.

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.95,
                  colors: [
                    c.accentSoft.withValues(alpha: c.isDark ? 0.55 : 0.45),
                    c.bg,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: alignment,
            child: Padding(
              padding: EdgeInsets.only(left: 18 * moveT, top: 14 * moveT),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: fade,
                  child: CompassMark(
                    size: 122,
                    color: c.inkSoft,
                    accent: c.accent,
                    stroke: 1.8,
                    needleAngle: angle,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 190),
              child: Opacity(
                opacity: fade * textFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '征途手札',
                      style: AppText.serifStyle(
                        size: 28,
                        color: c.ink,
                        letterSpacing: 6,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '把平凡的日子，写成一场冒险',
                      style: AppText.sans(
                        size: 11,
                        color: c.muted,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 54,
            child: Opacity(
              opacity: skipFade,
              child: Text(
                '轻触跳过',
                textAlign: TextAlign.center,
                style: AppText.sans(size: 10, color: c.muted, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
