/// 路由路径常量。新增路由时在此集中维护。
abstract final class Routes {
  static const onboarding = '/onboarding';

  // 主框架内的 4 个 tab——通过 [StatefulShellRoute] 持有共享 nav。
  static const weatherHome = '/weather';
  static const forecast = '/forecast';
  static const wardrobe = '/wardrobe';
  static const settings = '/settings';
}
