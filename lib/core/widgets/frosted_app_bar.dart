import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 磨砂玻璃顶栏——三个二级页（设置 / 衣橱 / 预报）共享。
///
/// 关键点：自定义 PreferredSizeWidget 不会被 Scaffold 自动加 status bar padding（Material AppBar 自身处理），
/// 因此必须在工厂里把 `viewPadding.top` 加进 [PreferredSize.preferredSize]，
/// 同时在内部用 [SafeArea] 把可视内容下推；
/// 模糊背景仍延伸到刘海/灵动岛区域，避免颜色断层。
PreferredSizeWidget buildFrostedAppBar(
  BuildContext context, {
  required String title,
}) {
  final topInset = MediaQuery.viewPaddingOf(context).top;
  return PreferredSize(
    preferredSize: Size.fromHeight(_toolbarHeight + topInset),
    child: _FrostedAppBar(title: title),
  );
}

const double _toolbarHeight = 64;

class _FrostedAppBar extends StatelessWidget {
  const _FrostedAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xCCFFFFFF), // rgba(255,255,255,0.8)
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: _toolbarHeight,
              child: Center(
                child: Text(
                  title,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
