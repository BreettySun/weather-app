import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav.dart';

/// 主框架——持有底部导航，承载 4 个 tab 的子路由。
///
/// `extendBody: true` 让磨砂玻璃 nav 浮在内容之上、可见模糊背景。
/// 各 tab 页内的可滚动内容应自行预留底部 padding（参考
/// [AppBottomNav.estimatedHeight]），避免被 nav 遮挡。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            // 重复点击当前 tab 时回到该 branch 的根路径。
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
