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
          return const [Color(0xFF141B12), Color(0xFF1D2A1A), Color(0xFF2A1E27)];
        case Season.summer:
          return const [Color(0xFF0E1B16), Color(0xFF122A20), Color(0xFF102C24)];
        case Season.autumn:
          return const [Color(0xFF1C1208), Color(0xFF2B1A09), Color(0xFF331B0B)];
        case Season.winter:
          return const [Color(0xFF0F171F), Color(0xFF16232D), Color(0xFF1A2C38)];
      }
    }
    switch (season) {
      case Season.spring:
        return const [Color(0xFFF8FBF2), Color(0xFFF3E7ED), Color(0xFFF8DCE8)];
      case Season.summer:
        return const [Color(0xFFF4FAEB), Color(0xFFDDF2DE), Color(0xFFD8EFE8)];
      case Season.autumn:
        return const [Color(0xFFFFF1C8), Color(0xFFF9D794), Color(0xFFF3BF83)];
      case Season.winter:
        return const [Color(0xFFFCFEFF), Color(0xFFF4F9FC), Color(0xFFE9F3F9)];
    }
  }

  static List<Color> hero(Season season, AppColors c) {
    if (c.isDark) {
      switch (season) {
        case Season.spring:
          return const [Color(0xFF22301D), Color(0xFF2C4025), Color(0xFF452B36)];
        case Season.summer:
          return const [Color(0xFF103024), Color(0xFF17402C), Color(0xFF153A30)];
        case Season.autumn:
          return const [Color(0xFF5C3B08), Color(0xFF66330B), Color(0xFF3A1C06)];
        case Season.winter:
          return const [Color(0xFF1B2E3C), Color(0xFF234252), Color(0xFF28495A)];
      }
    }
    switch (season) {
      case Season.spring:
        return const [Color(0xFFF4FBEE), Color(0xFFECD9E4), Color(0xFFF6C9D8)];
      case Season.summer:
        return const [Color(0xFFF4FAEA), Color(0xFFD5EFDA), Color(0xFFCBE9DD)];
      case Season.autumn:
        return const [Color(0xFFFFF0B4), Color(0xFFF7CE73), Color(0xFFEDB35F)];
      case Season.winter:
        return const [Color(0xFFFFFFFF), Color(0xFFF2F9FD), Color(0xFFE2EFF7)];
    }
  }

  static List<Color> weather(Season season, AppColors c, {required bool isDay}) {
    if (c.isDark) {
      switch (season) {
        case Season.spring:
          return isDay
              ? const [Color(0xFF2D3F25), Color(0xFF3C3A30), Color(0xFF4A2E3A)]
              : const [Color(0xFF182316), Color(0xFF1D2A1A), Color(0xFF2A1E27)];
        case Season.summer:
          return isDay
              ? const [Color(0xFF16452F), Color(0xFF17523A), Color(0xFF15483F)]
              : const [Color(0xFF0E241C), Color(0xFF112E24), Color(0xFF0E2B28)];
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
            ? const [Color(0xFFD8EBC8), Color(0xFFDCC9D7), Color(0xFFEDB9CD)]
            : const [Color(0xFFDFE8D4), Color(0xFFD9CAD9), Color(0xFFE6C1D4)];
      case Season.summer:
        return isDay
            ? const [Color(0xFFD8EFD8), Color(0xFFBBE4C5), Color(0xFFC0DDE5)]
            : const [Color(0xFFD7E9D6), Color(0xFFC3DFC8), Color(0xFFC3DCDD)];
      case Season.autumn:
        return isDay
            ? const [Color(0xFFF8DE9C), Color(0xFFF2C87C), Color(0xFFE9B06E)]
            : const [Color(0xFFF3D296), Color(0xFFEBBE7E), Color(0xFFE2A978)];
      case Season.winter:
        return isDay
            ? const [Color(0xFFF8FCFE), Color(0xFFEFF7FB), Color(0xFFE5F1F8)]
            : const [Color(0xFFF0F8FC), Color(0xFFE4F1F8), Color(0xFFD8E9F3)];
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
