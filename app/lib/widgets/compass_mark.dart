import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A small hand-drawn compass used as the app's emblem.
class CompassMark extends StatelessWidget {
  const CompassMark({
    super.key,
    this.size = 72,
    this.color,
    this.accent,
    this.rotating = false,
    this.stroke = 1.4,
  });

  final double size;
  final Color? color;
  final Color? accent;
  final bool rotating;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final painter = _CompassPainter(
      color: color ?? c.ink,
      accent: accent ?? c.accent,
      stroke: stroke,
    );
    if (!rotating) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: painter),
      );
    }
    return _RotatingCompass(size: size, painter: painter);
  }
}

class _RotatingCompass extends StatefulWidget {
  const _RotatingCompass({required this.size, required this.painter});

  final double size;
  final _CompassPainter painter;

  @override
  State<_RotatingCompass> createState() => _RotatingCompassState();
}

class _RotatingCompassState extends State<_RotatingCompass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.rotate(
          angle: _controller.value * math.pi * 2,
          child: CustomPaint(painter: widget.painter),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.color, required this.accent, required this.stroke});

  final Color color;
  final Color accent;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.scale(scale, scale);
    final center = const Offset(50, 50);
    final ring = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final faint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.7;

    canvas.drawCircle(center, 42, ring);
    canvas.drawCircle(center, 35, faint);

    for (var i = 0; i < 32; i++) {
      final angle = i * math.pi / 16;
      final inner = i % 8 == 0 ? 29.0 : (i % 4 == 0 ? 31.5 : 33.0);
      final outer = 35.5;
      final from = center + Offset(math.cos(angle), math.sin(angle)) * inner;
      final to = center + Offset(math.cos(angle), math.sin(angle)) * outer;
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = color.withValues(alpha: i % 8 == 0 ? 0.65 : 0.28)
          ..strokeWidth = i % 8 == 0 ? stroke : stroke * 0.7
          ..strokeCap = StrokeCap.round,
      );
    }

    // North needle, half filled.
    final needle = Path()
      ..moveTo(50, 17)
      ..lineTo(58, 50)
      ..lineTo(50, 50)
      ..close();
    canvas.drawPath(needle, Paint()..color = accent);
    final south = Path()
      ..moveTo(50, 83)
      ..lineTo(42, 50)
      ..lineTo(50, 50)
      ..close();
    canvas.drawPath(south, Paint()..color = color.withValues(alpha: 0.45));
    final eastWest = Path()
      ..moveTo(17, 50)
      ..lineTo(50, 42)
      ..lineTo(50, 50)
      ..lineTo(83, 50)
      ..lineTo(50, 58)
      ..lineTo(50, 50)
      ..close();
    canvas.drawPath(eastWest, Paint()..color = color.withValues(alpha: 0.16));

    canvas.drawCircle(center, 3.4, Paint()..color = color);
    canvas.drawCircle(center, 1.4, Paint()..color = accent);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.color != color || old.accent != accent || old.stroke != stroke;
}
