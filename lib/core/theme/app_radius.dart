import 'package:flutter/material.dart';

/// 圆角 token，源自 DESIGN.md（基于 1rem = 16px）。
///
/// 通过 [ThemeExtension] 注册到 [ThemeData.extensions]，
/// 在 widget 中通过 `Theme.of(context).extension<AppRadius>()!` 取值。
@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    this.sm = 8, // 0.5rem
    this.normal = 16, // 1rem (DEFAULT)
    this.md = 24, // 1.5rem
    this.lg = 32, // 2rem
    this.xl = 48, // 3rem
    this.full = 9999,
  });

  final double sm;
  final double normal;
  final double md;
  final double lg;
  final double xl;
  final double full;

  static const AppRadius standard = AppRadius();

  @override
  AppRadius copyWith({
    double? sm,
    double? normal,
    double? md,
    double? lg,
    double? xl,
    double? full,
  }) {
    return AppRadius(
      sm: sm ?? this.sm,
      normal: normal ?? this.normal,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      full: full ?? this.full,
    );
  }

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    double l(double a, double b) => a + (b - a) * t;
    return AppRadius(
      sm: l(sm, other.sm),
      normal: l(normal, other.normal),
      md: l(md, other.md),
      lg: l(lg, other.lg),
      xl: l(xl, other.xl),
      full: l(full, other.full),
    );
  }
}
