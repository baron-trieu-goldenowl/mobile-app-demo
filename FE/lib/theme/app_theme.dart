import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Brand palette. The app is dark-first (like most alarm apps, it is used
/// at night and right after waking up) with a warm "sunrise" accent.
class AppColors {
  AppColors._();

  static const accent = Color(0xFFFF6B4A);
  static const accentPink = Color(0xFFFF3D6E);
  static const violet = Color(0xFF7C6CFF);
  static const event = Color(0xFF4C9BFF);
  static const task = Color(0xFF2ECC9A);
  static const warning = Color(0xFFFFB443);
  static const danger = Color(0xFFFF4D5E);

  static const sunrise = LinearGradient(
    colors: [Color(0xFFFF8A4C), Color(0xFFFF3D6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const dusk = LinearGradient(
    colors: [Color(0xFF6A5CFF), Color(0xFFB45CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const night = LinearGradient(
    colors: [Color(0xFF1C2147), Color(0xFF0A0D1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const _darkBg = Color(0xFF0D1020);
  static const _lightBg = Color(0xFFF4F5FA);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.accent,
          onPrimary: Colors.white,
          secondary: AppColors.violet,
          error: AppColors.danger,
          surface: isDark ? AppColors._darkBg : AppColors._lightBg,
          onSurface: isDark ? const Color(0xFFF2F3F8) : const Color(0xFF151827),
          onSurfaceVariant: isDark
              ? const Color(0xFF9BA1B8)
              : const Color(0xFF6B7085),
          surfaceContainerLowest: isDark
              ? const Color(0xFF0A0C18)
              : Colors.white,
          surfaceContainerLow: isDark ? const Color(0xFF141830) : Colors.white,
          surfaceContainer: isDark ? const Color(0xFF181D36) : Colors.white,
          surfaceContainerHigh: isDark
              ? const Color(0xFF20263F)
              : const Color(0xFFEDEFF6),
          surfaceContainerHighest: isDark
              ? const Color(0xFF2A3150)
              : const Color(0xFFE3E6F0),
          outlineVariant: isDark
              ? const Color(0xFF262C47)
              : const Color(0xFFE2E4EE),
        );

    final radius = BorderRadius.circular(16);
    final textTheme =
        (isDark ? Typography.whiteMountainView : Typography.blackMountainView)
            .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
            .copyWith(
              headlineLarge: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              headlineMedium: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              titleLarge: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              titleMedium: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurface,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        thumbColor: AppColors.accent,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        overlayColor: AppColors.accent.withValues(alpha: 0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: AppColors.accent.withValues(alpha: 0.18),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: AppColors.accent,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent.withValues(alpha: 0.18)
                : scheme.surfaceContainerHigh,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent
                : scheme.onSurface,
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
        backgroundColor: isDark
            ? const Color(0xFF2A3150)
            : const Color(0xFF151827),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.accent,
        textTheme: CupertinoTextThemeData(
          dateTimePickerTextStyle: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
