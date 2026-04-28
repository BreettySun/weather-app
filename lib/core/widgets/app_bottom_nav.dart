import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 应用底部导航栏——磨砂玻璃 + 圆角顶。
///
/// 由 [StatefulShellRoute] 的外壳调用，保持挂载状态、跨 tab 切换不重启栈。
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavSpec>[
    _NavSpec('今日', 'assets/icons/nav_v2/today.svg'),
    _NavSpec('预报', 'assets/icons/nav_v2/forecast.svg'),
    _NavSpec('衣橱', 'assets/icons/nav_v2/wardrobe.svg'),
    _NavSpec('设置', 'assets/icons/nav_v2/settings.svg'),
  ];

  /// nav 总高度估算值——用于让 body 内可滚动内容预留底部 padding 不被遮挡。
  /// 不含底部 safe area；调用方按需自行加 [MediaQuery.viewPaddingOf].bottom。
  static const double estimatedHeight = 76;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _NavItem(
                      spec: _items[i],
                      active: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.label, this.asset);

  final String label;
  final String asset;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool active;
  final VoidCallback onTap;

  static const _inactiveColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryContainer : _inactiveColor;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 22,
              child: Center(
                child: SvgPicture.asset(
                  spec.asset,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              spec.label,
              style: AppTypography.labelCaps.copyWith(
                letterSpacing: 0,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
                height: 16.5 / 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
