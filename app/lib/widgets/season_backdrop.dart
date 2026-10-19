import 'package:flutter/material.dart';

import '../core/season_visuals.dart';
import '../core/theme.dart';

/// A full-screen seasonal wash placed behind the five main tabs.
/// It is intentionally quiet so cards stay readable, but the two seasonal
/// colors are always present in the atmosphere.
class SeasonBackdrop extends StatelessWidget {
  const SeasonBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final season = context.season;
    final colors = SeasonVisuals.backdrop(season, c);
    final glow = SeasonVisuals.glow(season, c);
    final secondary = SeasonVisuals.secondary(season, c);
    final size = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
          Positioned(
            top: -size.width * 0.30,
            right: -size.width * 0.24,
            child: _Glow(
              size: size.width * 0.95,
              color: glow,
              alpha: c.isDark ? 0.28 : 0.32,
            ),
          ),
          Positioned(
            bottom: -size.width * 0.38,
            left: -size.width * 0.30,
            child: _Glow(
              size: size.width * 0.92,
              color: secondary,
              alpha: c.isDark ? 0.20 : 0.22,
            ),
          ),
          Positioned(
            top: size.height * 0.36,
            left: -size.width * 0.42,
            child: _Ring(
              size: size.width * 0.72,
              color: glow.withValues(alpha: c.isDark ? 0.10 : 0.12),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.30,
            right: -size.width * 0.18,
            child: _Ring(
              size: size.width * 0.62,
              color: secondary.withValues(alpha: c.isDark ? 0.09 : 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.alpha});

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
    );
  }
}
