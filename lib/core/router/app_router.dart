import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/forecast/view/forecast_page.dart';
import '../../features/onboarding/view/onboarding_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/wardrobe/view/wardrobe_page.dart';
import '../../features/weather/view/weather_home_page.dart';
import 'routes.dart';

/// 全局路由。
///
/// 结构：
/// - `/onboarding`（shell 外，全屏）
/// - [StatefulShellRoute]（持有底部 nav，4 个 branch）：
///   - `/weather`（今日）
///   - `/forecast`（预报，占位）
///   - `/wardrobe`（衣橱，占位）
///   - `/settings`（设置）
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.onboarding,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.weatherHome,
                builder: (context, state) => const WeatherHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.forecast,
                builder: (context, state) => const ForecastPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.wardrobe,
                builder: (context, state) => const WardrobePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
