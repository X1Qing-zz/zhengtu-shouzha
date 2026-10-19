import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';

class DonutSlice {
  const DonutSlice({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 156,
    this.strokeWidth = 16,
    this.centerTitle,
    this.centerValue,
    this.centerCaption,
  });

  final List<DonutSlice> slices;
  final double size;
  final double strokeWidth;
  final String? centerTitle;
  final String? centerValue;
  final String? centerCaption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          return CustomPaint(
            painter: _DonutPainter(
              slices: total <= 0 ? const [] : slices,
              total: total,
              progress: progress,
              trackColor: c.line.withValues(alpha: 0.5),
              strokeWidth: strokeWidth,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerTitle != null)
                Text(
                  centerTitle!,
                  style: AppText.eyebrow(color: c.muted, size: 9),
                ),
              if (centerValue != null) ...[
                const SizedBox(height: 3),
                Text(
                  centerValue!,
                  style: AppText.displayStyle(size: size * 0.18, color: c.ink, letterSpacing: -0.5),
                ),
              ],
              if (centerCaption != null) ...[
                const SizedBox(height: 2),
                Text(
                  centerCaption!,
                  style: AppText.sans(size: 10, color: c.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.progress,
    required this.trackColor,
    required this.strokeWidth,
  });

  final List<DonutSlice> slices;
  final double total;
  final double progress;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);
    if (slices.isEmpty) return;

    var start = -math.pi / 2;
    const gap = 0.035;
    for (final slice in slices) {
      final sweep = (slice.value / total) * math.pi * 2 * progress;
      if (sweep <= 0.001) continue;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final effective = math.max(0.0, sweep - gap);
      if (effective > 0.001) {
        canvas.drawArc(rect, start + gap / 2, effective, false, paint);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.slices != slices || old.total != total;
}

class BarSeries extends StatelessWidget {
  const BarSeries({
    super.key,
    required this.values,
    required this.labels,
    this.height = 116,
    this.highlightIndex = -1,
    this.color,
    this.highlightColor,
    this.showValues = false,
    this.barWidth = 18,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final int highlightIndex;
  final Color? color;
  final Color? highlightColor;
  final bool showValues;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = values.fold<double>(0, (m, v) => math.max(m, v));
    final peak = maxValue <= 0 ? 1.0 : maxValue;
    final baseColor = color ?? c.line;
    final activeColor = highlightColor ?? c.accent;
    final valueSpace = showValues ? 18.0 : 0.0;
    final labelSpace = 26.0;
    final barSpace = height - valueSpace - labelSpace;

    return SizedBox(
      height: height + 4,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final ratio = (values[i] / peak).clamp(0.0, 1.0);
          final active = i == highlightIndex;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: valueSpace,
                  child: showValues && values[i] > 0
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            compactMoney(values[i]),
                            style: AppText.sans(
                              size: 9,
                              weight: active ? FontWeight.w600 : FontWeight.w500,
                              color: active ? c.accent : c.muted,
                            ),
                          ),
                        )
                      : null,
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) => Container(
                    width: barWidth,
                    height: math.max(v * barSpace, 3),
                    decoration: BoxDecoration(
                      color: active ? activeColor : baseColor.withValues(alpha: c.isDark ? 0.5 : 0.85),
                      borderRadius: BorderRadius.circular(barWidth / 2),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 16,
                  child: Text(
                    labels[i],
                    style: AppText.sans(
                      size: 9.5,
                      weight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? c.ink : c.muted,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.tone,
    this.caption,
  });

  final String value;
  final String label;
  final Color? tone;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppText.displayStyle(size: 28, color: tone ?? c.ink, height: 1),
        ),
        const SizedBox(height: 5),
        Text(label, style: AppText.sans(size: 10.5, color: c.muted, letterSpacing: 0.3)),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption!, style: AppText.sans(size: 9.5, color: c.muted.withValues(alpha: 0.8))),
        ],
      ],
    );
  }
}

class RatioBar extends StatelessWidget {
  const RatioBar({
    super.key,
    required this.ratio,
    this.height = 5,
    this.color,
    this.background,
    this.label,
  });

  final double ratio;
  final double height;
  final Color? color;
  final Color? background;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.sans(size: 10.5, color: c.muted)),
          const SizedBox(height: 5),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: height,
            backgroundColor: background ?? c.line.withValues(alpha: 0.55),
            valueColor: AlwaysStoppedAnimation(color ?? c.accent),
          ),
        ),
      ],
    );
  }
}
