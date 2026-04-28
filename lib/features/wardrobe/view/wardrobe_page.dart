import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 衣橱页占位。后续接用户衣物管理 / 历史穿搭 / 个性化推荐。
class WardrobePage extends StatelessWidget {
  const WardrobePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '衣橱',
          style: AppTypography.headlineH2.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '即将上线\n管理你的衣物、查看穿搭历史、获得个性化推荐。',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 24 / 16,
            ),
          ),
        ),
      ),
    );
  }
}
