import 'package:flutter/material.dart';

/// Material 3 颜色 token，源自 DESIGN.md 的 "Vibrant Morning" 配色。
///
/// 当前仅 light scheme，暗色 scheme 待后续设计输出后再补。
abstract final class AppColors {
  // Surface
  static const surface = Color(0xFFF9F9FE);
  static const surfaceDim = Color(0xFFD9DADE);
  static const surfaceBright = Color(0xFFF9F9FE);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F3F8);
  static const surfaceContainer = Color(0xFFEDEDF2);
  static const surfaceContainerHigh = Color(0xFFE8E8ED);
  static const surfaceContainerHighest = Color(0xFFE2E2E7);
  static const onSurface = Color(0xFF1A1C1F);
  static const onSurfaceVariant = Color(0xFF57423B);
  static const inverseSurface = Color(0xFF2E3034);
  static const inverseOnSurface = Color(0xFFF0F0F5);
  static const surfaceVariant = Color(0xFFE2E2E7);
  static const surfaceTint = Color(0xFFA43C12);

  // Outline
  static const outline = Color(0xFF8B7169);
  static const outlineVariant = Color(0xFFDEC0B6);

  // Primary
  static const primary = Color(0xFFA43C12);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFFF7F50);
  static const onPrimaryContainer = Color(0xFF6C2000);
  static const inversePrimary = Color(0xFFFFB59C);
  static const primaryFixed = Color(0xFFFFDBCF);
  static const primaryFixedDim = Color(0xFFFFB59C);
  static const onPrimaryFixed = Color(0xFF380C00);
  static const onPrimaryFixedVariant = Color(0xFF822800);

  // Secondary
  static const secondary = Color(0xFF0060AC);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF68ABFF);
  static const onSecondaryContainer = Color(0xFF003E73);
  static const secondaryFixed = Color(0xFFD4E3FF);
  static const secondaryFixedDim = Color(0xFFA4C9FF);
  static const onSecondaryFixed = Color(0xFF001C39);
  static const onSecondaryFixedVariant = Color(0xFF004883);

  // Tertiary
  static const tertiary = Color(0xFF705D00);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFC0A200);
  static const onTertiaryContainer = Color(0xFF453900);
  static const tertiaryFixed = Color(0xFFFFE16D);
  static const tertiaryFixedDim = Color(0xFFE9C400);
  static const onTertiaryFixed = Color(0xFF221B00);
  static const onTertiaryFixedVariant = Color(0xFF544600);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Background (Material 3 已弃用，保留兼容)
  static const background = Color(0xFFF9F9FE);
  static const onBackground = Color(0xFF1A1C1F);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: inverseOnSurface,
    inversePrimary: inversePrimary,
    surfaceTint: surfaceTint,
  );
}
