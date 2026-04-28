import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 应用主题入口。当前仅提供 light theme。
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = AppColors.lightScheme;
    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: const <ThemeExtension<dynamic>>[
        AppSpacing.standard,
        AppRadius.standard,
      ],
    );
  }
}
