import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_store.dart';
import '../../widgets/compass_mark.dart';
import '../onboarding.dart';
import '../shell.dart';

/// A short opening scene: the compass fades in, the needle makes three quarters
/// of a turn and settles north, then the emblem lands exactly on the small
/// compass of the page underneath. No page swap at the end.
class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
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
      duration: const Duration(milliseconds: 320),
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
        final progress = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            page,
            if (progress < 1)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _skip,
                  child: _LaunchScene(
                    progress: progress,
                    onboarded: store.onboarded,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LaunchScene extends StatelessWidget {
  const _LaunchScene({required this.progress, required this.onboarded});

  final double progress;
  final bool onboarded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = progress.clamp(0.0, 1.0);
    final screen = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;

    final fade = Curves.easeOutCubic.transform((p / 0.14).clamp(0.0, 1.0));
    final turnT = Curves.easeInOutCubic.transform(((p - 0.05) / 0.61).clamp(0.0, 1.0));
    final moveT = Curves.easeInOutCubic.transform(((p - 0.66) / 0.28).clamp(0.0, 1.0));
    final textFade = (1 - ((p - 0.52) / 0.14)).clamp(0.0, 1.0);
    final bgFade = 1 - Curves.easeInOutCubic.transform(((p - 0.78) / 0.16).clamp(0.0, 1.0));
    final skipFade = (1 - ((p - 0.62) / 0.16)).clamp(0.0, 1.0) * 0.7;

    // The target is deliberately identical to the compass in the page:
    // home: size 20, x 20, vertically centered in the 40px header row,
    //       so top = safeTop + 12 + (40 - 20) / 2 = safeTop + 22.
    // onboarding: size 28 at (28, safeTop + 18), ink, stroke 2.4.
    final target = onboarded
        ? Rect.fromLTWH(20, safeTop + 22, 20, 20)
        : Rect.fromLTWH(28, safeTop + 18, 28, 28);
    final start = Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height / 2),
      width: 122,
      height: 122,
    );
    final compassRect = Rect.lerp(start, target, moveT)!;
    final targetStroke = onboarded ? 3.0 : 2.4;
    final stroke = 1.8 + (targetStroke - 1.8) * moveT;
    final compassColor = onboarded ? c.inkSoft : c.ink;
    final glow = Color.alphaBlend(
      c.accentSoft.withValues(alpha: c.isDark ? 0.55 : 0.45),
      c.bg,
    );

    // Three quarters of a turn, starting east and settling north.
    final angle = -math.pi * 1.5 + turnT * math.pi * 1.5;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: bgFade,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: c.bg)),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.15),
                          radius: 0.95,
                          colors: [glow, c.bg],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fromRect(
            rect: compassRect,
            child: IgnorePointer(
              child: Opacity(
                opacity: fade,
                child: CompassMark(
                  size: compassRect.width,
                  color: compassColor,
                  accent: c.accent,
                  stroke: stroke,
                  needleAngle: angle,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 190),
              child: IgnorePointer(
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
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 54,
            child: IgnorePointer(
              child: Opacity(
                opacity: skipFade,
                child: Text(
                  '轻触跳过',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 10, color: c.muted, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
