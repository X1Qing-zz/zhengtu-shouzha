import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'season.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.sunken,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.moss,
    required this.mossSoft,
    required this.terra,
    required this.terraSoft,
    required this.gold,
    required this.sky,
    required this.shadow,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color raised;
  final Color sunken;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color moss;
  final Color mossSoft;
  final Color terra;
  final Color terraSoft;
  final Color gold;
  final Color sky;
  final Color shadow;
  final bool isDark;

  static const AppColors light = AppColors(
    bg: Color(0xFFF6F1E6),
    surface: Color(0xFFFEFBF5),
    raised: Color(0xFFFFFDF9),
    sunken: Color(0xFFEDE4D4),
    ink: Color(0xFF25221C),
    inkSoft: Color(0xFF4B463B),
    muted: Color(0xFF8C8272),
    line: Color(0xFFE3D8C5),
    accent: Color(0xFFA6693B),
    accentSoft: Color(0xFFF0E0CB),
    moss: Color(0xFF5D7058),
    mossSoft: Color(0xFFE1E8DA),
    terra: Color(0xFFB0563F),
    terraSoft: Color(0xFFF5E0D8),
    gold: Color(0xFFC29A45),
    sky: Color(0xFF7896A2),
    shadow: Color(0xFF6B5843),
    isDark: false,
  );

  static const AppColors dark = AppColors(
    bg: Color(0xFF14130F),
    surface: Color(0xFF1D1B16),
    raised: Color(0xFF24211B),
    sunken: Color(0xFF100F0C),
    ink: Color(0xFFF3EBDD),
    inkSoft: Color(0xFFD8CEBD),
    muted: Color(0xFF998E7C),
    line: Color(0xFF352F26),
    accent: Color(0xFFD4A46C),
    accentSoft: Color(0xFF3B2E21),
    moss: Color(0xFF94AA8B),
    mossSoft: Color(0xFF2A3329),
    terra: Color(0xFFD68A72),
    terraSoft: Color(0xFF3D2923),
    gold: Color(0xFFE2C077),
    sky: Color(0xFF93ADB7),
    shadow: Color(0xFF000000),
    isDark: true,
  );

  /// Spring: tender green + pink.
  static final AppColors springLight = light.copyWith(
    bg: const Color(0xFFFAF6F1),
    surface: const Color(0xFFFFFBF8),
    raised: const Color(0xFFFFFFFF),
    sunken: const Color(0xFFF1E7E9),
    ink: const Color(0xFF292A24),
    inkSoft: const Color(0xFF505247),
    muted: const Color(0xFF8A8C7D),
    line: const Color(0xFFEADBDD),
    accent: const Color(0xFF63825A),
    accentSoft: const Color(0xFFE6EFDE),
    moss: const Color(0xFF5F7F52),
    mossSoft: const Color(0xFFE2ECDC),
    terra: const Color(0xFFC45F7C),
    terraSoft: const Color(0xFFF7DCE6),
    gold: const Color(0xFFC7A65A),
    sky: const Color(0xFF8DA9A2),
    shadow: const Color(0xFF5D584A),
  );

  static final AppColors springDark = dark.copyWith(
    bg: const Color(0xFF12160F),
    surface: const Color(0xFF1A2118),
    raised: const Color(0xFF222B1F),
    sunken: const Color(0xFF0D110C),
    ink: const Color(0xFFF3EFE3),
    inkSoft: const Color(0xFFD4D0C2),
    muted: const Color(0xFF969486),
    line: const Color(0xFF313A2B),
    accent: const Color(0xFFA8C79A),
    accentSoft: const Color(0xFF2A3524),
    moss: const Color(0xFF9DBA8E),
    mossSoft: const Color(0xFF273324),
    terra: const Color(0xFFE98FA9),
    terraSoft: const Color(0xFF3A252B),
    gold: const Color(0xFFD9BC7A),
    sky: const Color(0xFF9DBBB0),
  );

  /// Summer: vivid green + blue.
  static final AppColors summerLight = light.copyWith(
    bg: const Color(0xFFF3F7E9),
    surface: const Color(0xFFFBFDF6),
    raised: const Color(0xFFFFFFFF),
    sunken: const Color(0xFFE5EDDC),
    ink: const Color(0xFF1F2A24),
    inkSoft: const Color(0xFF46564C),
    muted: const Color(0xFF7D8A80),
    line: const Color(0xFFD4E1D2),
    accent: const Color(0xFF2E7D4F),
    accentSoft: const Color(0xFFD8ECDD),
    moss: const Color(0xFF236B48),
    mossSoft: const Color(0xFFD4E9D9),
    terra: const Color(0xFFC26A4A),
    terraSoft: const Color(0xFFF3DFD7),
    gold: const Color(0xFFC7A64A),
    sky: const Color(0xFF4C7E9E),
    shadow: const Color(0xFF3E5548),
  );

  static final AppColors summerDark = dark.copyWith(
    bg: const Color(0xFF0F1512),
    surface: const Color(0xFF171F1A),
    raised: const Color(0xFF1F2A23),
    sunken: const Color(0xFF0B100D),
    ink: const Color(0xFFEDF3EA),
    inkSoft: const Color(0xFFC9D7CC),
    muted: const Color(0xFF8EA194),
    line: const Color(0xFF2A3A30),
    accent: const Color(0xFF86D09C),
    accentSoft: const Color(0xFF20382A),
    moss: const Color(0xFF9ADBAF),
    mossSoft: const Color(0xFF1D3326),
    terra: const Color(0xFFE09A78),
    terraSoft: const Color(0xFF38251F),
    gold: const Color(0xFFDCC06C),
    sky: const Color(0xFF7FB6D4),
  );

  /// Autumn: gold + orange-red, distinct from the old warm-paper copper.
  static final AppColors autumnLight = light.copyWith(
    bg: const Color(0xFFFFF3CE),
    surface: const Color(0xFFFFF9DF),
    raised: const Color(0xFFFFFCF0),
    sunken: const Color(0xFFF3E0B2),
    ink: const Color(0xFF2C2415),
    inkSoft: const Color(0xFF59492E),
    muted: const Color(0xFF8F7A54),
    line: const Color(0xFFEBD29C),
    accent: const Color(0xFFC28A10),
    accentSoft: const Color(0xFFF8E2A8),
    moss: const Color(0xFF7A7D35),
    mossSoft: const Color(0xFFECEBCB),
    terra: const Color(0xFFD2622C),
    terraSoft: const Color(0xFFF8D8C2),
    gold: const Color(0xFFE2A916),
    sky: const Color(0xFF8F9A72),
    shadow: const Color(0xFF6B4B1C),
  );

  static final AppColors autumnDark = dark.copyWith(
    bg: const Color(0xFF171208),
    surface: const Color(0xFF21190D),
    raised: const Color(0xFF2B2111),
    sunken: const Color(0xFF100B05),
    ink: const Color(0xFFF8EBCF),
    inkSoft: const Color(0xFFDCC7A2),
    muted: const Color(0xFFA28A62),
    line: const Color(0xFF3B2C18),
    accent: const Color(0xFFEDB84C),
    accentSoft: const Color(0xFF3A2B12),
    moss: const Color(0xFFB3B36A),
    mossSoft: const Color(0xFF2F2F1A),
    terra: const Color(0xFFEA7C4B),
    terraSoft: const Color(0xFF3F2416),
    gold: const Color(0xFFF6CC63),
    sky: const Color(0xFFB5A074),
  );

  /// Winter: snow white + grey-blue.
  static final AppColors winterLight = light.copyWith(
    bg: const Color(0xFFF8FBFD),
    surface: const Color(0xFFFEFFFF),
    raised: const Color(0xFFFFFFFF),
    sunken: const Color(0xFFEEF4F8),
    ink: const Color(0xFF24303A),
    inkSoft: const Color(0xFF4B5B68),
    muted: const Color(0xFF8494A1),
    line: const Color(0xFFE3EDF3),
    accent: const Color(0xFF6B8DA5),
    accentSoft: const Color(0xFFEDF4F9),
    moss: const Color(0xFF6E8B7A),
    mossSoft: const Color(0xFFE2ECE6),
    terra: const Color(0xFFB56A5E),
    terraSoft: const Color(0xFFF3E2DF),
    gold: const Color(0xFFB08A4E),
    sky: const Color(0xFF8FB6CE),
    shadow: const Color(0xFF4B5C6B),
  );

  static final AppColors winterDark = dark.copyWith(
    bg: const Color(0xFF0F1419),
    surface: const Color(0xFF171E24),
    raised: const Color(0xFF1F2931),
    sunken: const Color(0xFF0B0F13),
    ink: const Color(0xFFEDF3F7),
    inkSoft: const Color(0xFFCBD7DF),
    muted: const Color(0xFF8B9BA7),
    line: const Color(0xFF2C3842),
    accent: const Color(0xFFA9C4D6),
    accentSoft: const Color(0xFF24333E),
    moss: const Color(0xFF93B3A0),
    mossSoft: const Color(0xFF203028),
    terra: const Color(0xFFD58E80),
    terraSoft: const Color(0xFF362421),
    gold: const Color(0xFFD6BC82),
    sky: const Color(0xFF8EBDD8),
  );

  static AppColors forSeason(Season season, Brightness brightness) {
    final darkMode = brightness == Brightness.dark;
    switch (season) {
      case Season.spring:
        return darkMode ? springDark : springLight;
      case Season.summer:
        return darkMode ? summerDark : summerLight;
      case Season.autumn:
        return darkMode ? autumnDark : autumnLight;
      case Season.winter:
        return darkMode ? winterDark : winterLight;
    }
  }

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? raised,
    Color? sunken,
    Color? ink,
    Color? inkSoft,
    Color? muted,
    Color? line,
    Color? accent,
    Color? accentSoft,
    Color? moss,
    Color? mossSoft,
    Color? terra,
    Color? terraSoft,
    Color? gold,
    Color? sky,
    Color? shadow,
    bool? isDark,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      sunken: sunken ?? this.sunken,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      moss: moss ?? this.moss,
      mossSoft: mossSoft ?? this.mossSoft,
      terra: terra ?? this.terra,
      terraSoft: terraSoft ?? this.terraSoft,
      gold: gold ?? this.gold,
      sky: sky ?? this.sky,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      raised: mix(raised, other.raised),
      sunken: mix(sunken, other.sunken),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      accent: mix(accent, other.accent),
      accentSoft: mix(accentSoft, other.accentSoft),
      moss: mix(moss, other.moss),
      mossSoft: mix(mossSoft, other.mossSoft),
      terra: mix(terra, other.terra),
      terraSoft: mix(terraSoft, other.terraSoft),
      gold: mix(gold, other.gold),
      sky: mix(sky, other.sky),
      shadow: mix(shadow, other.shadow),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
  TextTheme get texts => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Season get season => Season.of(DateTime.now());
  Color get bg => colors.bg;
  Color get surface => colors.surface;
  Color get ink => colors.ink;
  Color get muted => colors.muted;
  Color get accent => colors.accent;
  Color get line => colors.line;
}

class AppText {
  static const String serif = 'NotoSerifSC';
  static const String display = 'Cormorant';

  static TextStyle serifStyle({
    double size = 20,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double height = 1.32,
    double letterSpacing = 0.4,
    FontStyle? style,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: style,
    );
  }

  static TextStyle displayStyle({
    double size = 40,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.0,
    double letterSpacing = -1,
    FontStyle? style,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: style,
      fontFeatures: const [FontFeature.liningFigures(), FontFeature.tabularFigures()],
    );
  }

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.6,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle eyebrow({Color? color, double size = 10.5}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 2.4,
      height: 1.2,
      fontFamily: display,
    );
  }
}

TextTheme buildTextTheme(AppColors c) {
  return TextTheme(
    displayLarge: AppText.displayStyle(size: 58, color: c.ink, height: 0.95),
    displayMedium: AppText.displayStyle(size: 42, color: c.ink, height: 1.0),
    displaySmall: AppText.displayStyle(size: 32, color: c.ink, height: 1.0),
    headlineLarge: AppText.serifStyle(size: 28, color: c.ink, height: 1.3),
    headlineMedium: AppText.serifStyle(size: 23, color: c.ink, height: 1.35),
    headlineSmall: AppText.serifStyle(size: 19, color: c.ink, height: 1.4),
    titleLarge: AppText.sans(size: 18, weight: FontWeight.w600, color: c.ink, height: 1.3),
    titleMedium: AppText.sans(size: 15.5, weight: FontWeight.w600, color: c.ink, height: 1.4),
    titleSmall: AppText.sans(size: 13.5, weight: FontWeight.w600, color: c.inkSoft, height: 1.4),
    bodyLarge: AppText.sans(size: 15.5, color: c.ink, height: 1.75),
    bodyMedium: AppText.sans(size: 14, color: c.inkSoft, height: 1.7),
    bodySmall: AppText.sans(size: 12.5, color: c.muted, height: 1.6),
    labelLarge: AppText.sans(size: 14, weight: FontWeight.w600, color: c.ink),
    labelMedium: AppText.sans(size: 12, weight: FontWeight.w500, color: c.inkSoft, letterSpacing: 0.2),
    labelSmall: AppText.eyebrow(color: c.muted),
  );
}

ThemeData buildTheme(Brightness brightness, {DateTime? now}) {
  final c = AppColors.forSeason(Season.of(now ?? DateTime.now()), brightness);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: brightness == Brightness.dark ? const Color(0xFF1B140C) : const Color(0xFFFFFBF5),
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.ink,
    secondary: c.moss,
    onSecondary: brightness == Brightness.dark ? const Color(0xFF10170F) : Colors.white,
    secondaryContainer: c.mossSoft,
    onSecondaryContainer: c.ink,
    tertiary: c.terra,
    onTertiary: Colors.white,
    tertiaryContainer: c.terraSoft,
    onTertiaryContainer: c.ink,
    error: c.terra,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkSoft,
    outline: c.line,
    outlineVariant: c.line,
    shadow: c.shadow,
    scrim: Colors.black,
    inverseSurface: c.ink,
    onInverseSurface: c.bg,
    inversePrimary: c.accentSoft,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    splashFactory: InkRipple.splashFactory,
    textTheme: buildTextTheme(c),
    extensions: <ThemeExtension<dynamic>>[c],
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: c.ink,
      centerTitle: false,
      titleTextStyle: AppText.serifStyle(size: 20, color: c.ink),
      iconTheme: IconThemeData(color: c.ink, size: 22),
    ),
    iconTheme: IconThemeData(color: c.inkSoft, size: 22),
    dividerTheme: DividerThemeData(color: c.line, thickness: 0.8, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.line),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: AppText.sans(size: 14, color: c.muted),
      labelStyle: AppText.sans(size: 13.5, color: c.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.accent, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.terra),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: AppText.sans(size: 13.5, color: c.bg),
      actionTextColor: c.gold,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        textStyle: AppText.sans(size: 13.5, weight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.bg,
        textStyle: AppText.sans(size: 14.5, weight: FontWeight.w600, letterSpacing: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.line),
        textStyle: AppText.sans(size: 14, weight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.surface,
      headerBackgroundColor: c.surface,
      headerForegroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      todayBorder: BorderSide(color: c.accent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
