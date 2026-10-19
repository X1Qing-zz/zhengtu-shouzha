import 'package:flutter/material.dart';

import 'season.dart';
import 'theme.dart';

/// The visual bridge between a season and the semantic color tokens.
/// Every season has a primary (`accent`) and a second color that is allowed
/// to appear in large surfaces, not just in small labels.
class SeasonVisuals {
  const SeasonVisuals._();

  static Color secondary(Season season, AppColors c) {
    switch (season) {
      case Season.spring:
        return c.terra; // pink
      case Season.summer:
        return c.sky; // blue
      case Season.autumn:
        return c.terra; // orange-red
      case Season.winter:
        return c.sky; // grey-blue
    }
  }

  static List<Color> backdrop(Season season, AppColors c) {
    if (c.isDark) {
      switch (season) {
        case Season.spring:
          return const [Color(0xFF141B12), Color(0xFF1D2A1A), Color(0xFF241B22)];
        case Season.summer:
          return const [Color(0xFF0E1B16), Color(0xFF122A20), Color(0xFF102833)];
        case Season.autumn:
          return const [Color(0xFF1C1208), Color(0xFF2A190B), Color(0xFF32190D)];
        case Season.winter:
          return const [Color(0xFF0F171F), Color(0xFF16232D), Color(0xFF1A2C38)];
      }
    }
    switch (season) {
      case Season.spring:
        return const [Color(0xFFF7FBF1), Color(0xFFECF5E2), Color(0xFFF9E8EE)];
      case Season.summer:
        return const [Color(0xFFF6FAEE), Color(0xFFE2F2E7), Color(0xFFDFF0F8)];
      case Season.autumn:
        return const [Color(0xFFFFF3D6), Color(0xFFFBE2B4), Color(0xFFF8D0B1)];
      case Season.winter:
        return const [Color(0xFFF8FBFD), Color(0xFFE9F2F8), Color(0xFFDEEBF3)];
    }
  }

  static List<Color> hero(Season season, AppColors c) {
    if (c.isDark) {
      switch (season) {
        case Season.spring:
          return const [Color(0xFF22301D), Color(0xFF2C4025), Color(0xFF3A252D)];
        case Season.summer:
          return const [Color(0xFF103024), Color(0xFF143B2B), Color(0xFF153448)];
        case Season.autumn:
          return const [Color(0xFF5A360C), Color(0xFF6A2E10), Color(0xFF3C1B09)];
        case Season.winter:
          return const [Color(0xFF1B2E3C), Color(0xFF234252), Color(0xFF28495A)];
      }
    }
    switch (season) {
      case Season.spring:
        return const [Color(0xFFF4FBEE), Color(0xFFE1F1D8), Color(0xFFF8DEE6)];
      case Season.summer:
        return const [Color(0xFFF6FAEA), Color(0xFFD8EFDF), Color(0xFFD2E8F4)];
      case Season.autumn:
        return const [Color(0xFFFFF1C6), Color(0xFFF9D28B), Color(0xFFF2AC7C)];
      case Season.winter:
        return const [Color(0xFFF9FDFF), Color(0xFFDFEDF7), Color(0xFFC9DDEB)];
    }
  }

  static List<Color> weather(Season season, AppColors c, {required bool isDay}) {
    if (c.isDark) {
      switch (season) {
        case Season.spring:
          return isDay
              ? const [Color(0xFF2A3A24), Color(0xFF33492B), Color(0xFF3D2C33)]
              : const [Color(0xFF182316), Color(0xFF1D2A1A), Color(0xFF251B22)];
        case Season.summer:
          return isDay
              ? const [Color(0xFF16402F), Color(0xFF17483A), Color(0xFF153E4F)]
              : const [Color(0xFF0E241C), Color(0xFF112E24), Color(0xFF0E2934)];
        case Season.autumn:
          return isDay
              ? const [Color(0xFF6A4313), Color(0xFF7A3F16), Color(0xFF4A2210)]
              : const [Color(0xFF3A240C), Color(0xFF4A2410), Color(0xFF2A1408)];
        case Season.winter:
          return isDay
              ? const [Color(0xFF243B4A), Color(0xFF2B4B5E), Color(0xFF31576B)]
              : const [Color(0xFF12212C), Color(0xFF1A2E3C), Color(0xFF203A4A)];
      }
    }
    switch (season) {
      case Season.spring:
        return isDay
            ? const [Color(0xFFD4E9C2), Color(0xFFB7D8AB), Color(0xFFECC3D0)]
            : const [Color(0xFFD8E5D0), Color(0xFFC9DBD0), Color(0xFFE2D0DD)];
      case Season.summer:
        return isDay
            ? const [Color(0xFFD8EFE3), Color(0xFFC2E4E0), Color(0xFFC2DCEC)]
            : const [Color(0xFFD3E5E2), Color(0xFFBED8E2), Color(0xFFC2D2E6)];
      case Season.autumn:
        return isDay
            ? const [Color(0xFFF8E2AE), Color(0xFFF3CE97), Color(0xFFEEB79B)]
            : const [Color(0xFFF3D6B0), Color(0xFFEBC4A2), Color(0xFFE8B8AF)];
      case Season.winter:
        return isDay
            ? const [Color(0xFFEAF4FA), Color(0xFFD9E8F2), Color(0xFFCDE0EC)]
            : const [Color(0xFFDDEAF3), Color(0xFFCBDDE9), Color(0xFFC0D3E2)];
    }
  }

  static Color glow(Season season, AppColors c) {
    switch (season) {
      case Season.spring:
        return c.moss;
      case Season.summer:
        return c.accent;
      case Season.autumn:
        return c.gold;
      case Season.winter:
        return c.sky;
    }
  }

  /// Text color that works on top of the weather gradient.
  static Color weatherInk(List<Color> colors, AppColors c) {
    final darkCard = colors[1].computeLuminance() < 0.42;
    if (darkCard) return c.isDark ? c.ink : const Color(0xFFF8FCF8);
    return c.ink;
  }
}
