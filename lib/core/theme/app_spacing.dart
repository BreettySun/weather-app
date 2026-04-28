import 'package:flutter/material.dart';

/// 间距 token，源自 DESIGN.md。
///
/// 通过 [ThemeExtension] 注册到 [ThemeData.extensions]，
/// 在 widget 中通过 `Theme.of(context).extension<AppSpacing>()!` 取值。
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.base = 4,
    this.xs = 8,
    this.sm = 16,
    this.md = 24,
    this.lg = 32,
    this.xl = 48,
    this.safeMargin = 20,
  });

  final double base;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double safeMargin;

  static const AppSpacing standard = AppSpacing();

  @override
  AppSpacing copyWith({
    double? base,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? safeMargin,
  }) {
    return AppSpacing(
      base: base ?? this.base,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      safeMargin: safeMargin ?? this.safeMargin,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      base: lerpDouble(base, other.base, t),
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      safeMargin: lerpDouble(safeMargin, other.safeMargin, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
