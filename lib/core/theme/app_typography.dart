import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 字体样式 token，源自 DESIGN.md。
///
/// 框架阶段使用 google_fonts 包动态加载 Plus Jakarta Sans。
/// 生产期可下载 ttf 至 assets/fonts/ 并在 pubspec.yaml 中注册，
/// 然后将本文件的 GoogleFonts.plusJakartaSans(...) 改为
/// TextStyle(fontFamily: 'PlusJakartaSans', ...)。
abstract final class AppTypography {
  static TextStyle get display => GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 48 / 40,
    letterSpacing: -0.02 * 40,
  );

  static TextStyle get headlineH1 => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 38 / 32,
    letterSpacing: -0.01 * 32,
  );

  static TextStyle get headlineH2 => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 30 / 24,
  );

  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 26 / 18,
  );

  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static TextStyle get labelCaps => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    letterSpacing: 0.05 * 12,
  );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
  );

  /// 把 DESIGN.md 的 7 套样式映射到 Material 3 [TextTheme]。
  /// 映射策略：display→displayMedium，headline-h1→headlineLarge，
  /// headline-h2→headlineMedium，body-lg→bodyLarge，body-md→bodyMedium，
  /// label-caps→labelSmall，button→labelLarge。
  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: display,
    headlineLarge: headlineH1,
    headlineMedium: headlineH2,
    headlineSmall: headlineH2,
    titleLarge: headlineH2,
    titleMedium: bodyLg,
    titleSmall: bodyMd,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodyMd,
    labelLarge: button,
    labelMedium: button,
    labelSmall: labelCaps,
  );
}
