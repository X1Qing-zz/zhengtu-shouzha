import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';

class WeatherVisuals {
  static List<Color> gradient(WeatherKind kind, {required bool dark, bool isDay = true}) {
    if (!isDay) {
      return dark
          ? const [Color(0xFF25313E), Color(0xFF111820)]
          : const [Color(0xFF3B4C5C), Color(0xFF22303C)];
    }
    if (dark) {
      switch (kind) {
        case WeatherKind.sunny:
          return const [Color(0xFF5F4826), Color(0xFF2E2413)];
        case WeatherKind.clearNight:
          return const [Color(0xFF25313E), Color(0xFF111820)];
        case WeatherKind.partly:
          return const [Color(0xFF40402F), Color(0xFF23241B)];
        case WeatherKind.cloudy:
          return const [Color(0xFF383630), Color(0xFF211F1A)];
        case WeatherKind.fog:
          return const [Color(0xFF39352D), Color(0xFF201E19)];
        case WeatherKind.drizzle:
        case WeatherKind.rain:
          return const [Color(0xFF2C3B41), Color(0xFF172126)];
        case WeatherKind.snow:
          return const [Color(0xFF37444A), Color(0xFF1C252A)];
        case WeatherKind.thunder:
          return const [Color(0xFF333D48), Color(0xFF171D24)];
      }
    }
    switch (kind) {
      case WeatherKind.sunny:
        return const [Color(0xFFF6DFB2), Color(0xFFE9C07E)];
      case WeatherKind.clearNight:
        return const [Color(0xFF3B4C5C), Color(0xFF22303C)];
      case WeatherKind.partly:
        return const [Color(0xFFE8E3D5), Color(0xFFC9D3CF)];
      case WeatherKind.cloudy:
        return const [Color(0xFFE0DBD0), Color(0xFFC2BBB0)];
      case WeatherKind.fog:
        return const [Color(0xFFE5DED0), Color(0xFFC9C1B2)];
      case WeatherKind.drizzle:
      case WeatherKind.rain:
        return const [Color(0xFFD3DEDF), Color(0xFFA0B4B8)];
      case WeatherKind.snow:
        return const [Color(0xFFEDF2F2), Color(0xFFCBD9DC)];
      case WeatherKind.thunder:
        return const [Color(0xFFB7C1C8), Color(0xFF85939D)];
    }
  }

  static Color ink(WeatherKind kind, {required bool dark, bool isDay = true}) {
    if (!isDay) return const Color(0xFFF5EEE2);
    if (dark) return const Color(0xFFF5EEE2);
    if (kind == WeatherKind.rain || kind == WeatherKind.thunder || kind == WeatherKind.drizzle) {
      return const Color(0xFF1D2B30);
    }
    return const Color(0xFF2A251D);
  }

  static Color softInk(WeatherKind kind, {required bool dark, bool isDay = true}) {
    return ink(kind, dark: dark, isDay: isDay).withValues(alpha: 0.66);
  }
}

class WeatherGlyph extends StatelessWidget {
  const WeatherGlyph({
    super.key,
    required this.kind,
    this.size = 64,
    this.color,
    this.accent,
  });

  final WeatherKind kind;
  final double size;
  final Color? color;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WeatherPainter(
          kind: kind,
          color: color ?? c.ink,
          accent: accent ?? c.gold,
          rain: color ?? c.sky,
        ),
      ),
    );
  }
}

class _WeatherPainter extends CustomPainter {
  _WeatherPainter({
    required this.kind,
    required this.color,
    required this.accent,
    required this.rain,
  });

  final WeatherKind kind;
  final Color color;
  final Color accent;
  final Color rain;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.scale(scale, scale);

    final cloudPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final accentLine = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case WeatherKind.sunny:
        _sun(canvas, const Offset(50, 50), 18, accentPaint, accentLine);
        break;
      case WeatherKind.clearNight:
        _moon(canvas, const Offset(50, 50), 25, accentPaint);
        _stars(canvas, accentPaint, const [
          Offset(24, 28),
          Offset(74, 24),
          Offset(80, 66),
        ]);
        break;
      case WeatherKind.partly:
        _sun(canvas, const Offset(65, 32), 12, accentPaint, accentLine);
        _cloud(canvas, const Offset(-3, 18), 0.85, cloudPaint);
        break;
      case WeatherKind.cloudy:
        _cloud(canvas, const Offset(12, 8), 0.72, cloudPaint, opacity: 0.55);
        _cloud(canvas, const Offset(-2, 18), 0.92, cloudPaint);
        break;
      case WeatherKind.fog:
        _cloud(canvas, const Offset(-2, 8), 0.9, cloudPaint);
        for (var i = 0; i < 3; i++) {
          final y = 83.0 + i * 7;
          final inset = 18.0 + i * 7;
          canvas.drawLine(Offset(inset, y), Offset(100 - inset - 4, y), linePaint..color = color.withValues(alpha: 0.55));
        }
        break;
      case WeatherKind.drizzle:
        _cloud(canvas, const Offset(-2, 6), 0.9, cloudPaint);
        for (var i = 0; i < 3; i++) {
          final x = 30.0 + i * 19;
          canvas.drawLine(Offset(x, 80), Offset(x - 4, 91), linePaint..color = rain);
        }
        break;
      case WeatherKind.rain:
        _cloud(canvas, const Offset(-2, 4), 0.9, cloudPaint);
        for (var i = 0; i < 4; i++) {
          final x = 24.0 + i * 16;
          canvas.drawLine(Offset(x + 3, 79), Offset(x - 5, 96), linePaint..color = rain..strokeWidth = 3.8);
        }
        break;
      case WeatherKind.snow:
        _cloud(canvas, const Offset(-2, 4), 0.9, cloudPaint);
        for (var i = 0; i < 3; i++) {
          _snowflake(canvas, Offset(28.0 + i * 21, 87), 5.5, linePaint..color = rain);
        }
        break;
      case WeatherKind.thunder:
        _cloud(canvas, const Offset(-2, 2), 0.9, cloudPaint);
        final bolt = Path()
          ..moveTo(54, 68)
          ..lineTo(43, 87)
          ..lineTo(53, 86)
          ..lineTo(46, 101)
          ..lineTo(66, 80)
          ..lineTo(55, 81)
          ..close();
        canvas.drawPath(bolt, accentPaint);
        break;
    }

    canvas.restore();
  }

  void _sun(Canvas canvas, Offset center, double radius, Paint fill, Paint line) {
    canvas.drawCircle(
      center,
      radius * 1.55,
      Paint()..color = accent.withValues(alpha: 0.14),
    );
    canvas.drawCircle(center, radius, fill);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final from = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 7);
      final to = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 13);
      canvas.drawLine(from, to, line);
    }
  }

  void _moon(Canvas canvas, Offset center, double radius, Paint fill) {
    final outer = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final cutout = Path()
      ..addOval(Rect.fromCircle(center: center + const Offset(12, -9), radius: radius * 0.86));
    final crescent = Path.combine(PathOperation.difference, outer, cutout);
    canvas.drawPath(crescent, fill);
  }

  void _stars(Canvas canvas, Paint paint, List<Offset> stars) {
    for (final star in stars) {
      canvas.drawCircle(star, 2.3, paint..color = accent);
      canvas.drawCircle(star, 4.8, Paint()..color = accent.withValues(alpha: 0.16));
    }
  }

  void _snowflake(Canvas canvas, Offset center, double radius, Paint paint) {
    for (var i = 0; i < 3; i++) {
      final angle = i * math.pi / 3;
      final delta = Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(center - delta, center + delta, paint);
    }
  }

  Path _cloudPath() {
    return Path()
      ..moveTo(22, 70)
      ..cubicTo(9, 70, 5, 56, 16, 49)
      ..cubicTo(12, 33, 31, 24, 41, 35)
      ..cubicTo(48, 21, 68, 22, 73, 38)
      ..cubicTo(87, 36, 94, 51, 84, 61)
      ..cubicTo(90, 69, 84, 78, 74, 78)
      ..lineTo(24, 78)
      ..cubicTo(15, 78, 12, 73, 22, 70)
      ..close();
  }

  void _cloud(Canvas canvas, Offset offset, double scale, Paint paint, {double opacity = 1}) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.drawPath(_cloudPath(), paint..color = color.withValues(alpha: opacity));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter old) =>
      old.kind != kind || old.color != color || old.accent != accent || old.rain != rain;
}
