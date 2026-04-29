import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';

/// 占满父级可视区的可滚动壳——给 loading / error 用，
/// 让 [RefreshIndicator] 始终能通过 overscroll 触发。
///
/// 内边距已为底部 nav 预留高度，子内容可放心居中。
class ScrollableFill extends StatelessWidget {
  const ScrollableFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: AppBottomNav.estimatedHeight + bottomInset,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight -
                  AppBottomNav.estimatedHeight -
                  bottomInset,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
