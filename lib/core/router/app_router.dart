import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/forecast/view/forecast_page.dart';
import '../../features/onboarding/view/onboarding_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/wardrobe/view/wardrobe_page.dart';
import '../../features/weather/controller/location_provider.dart';
import '../../features/weather/model/geo_location.dart';
import '../../features/weather/view/city_search_page.dart';
import '../../features/weather/view/weather_home_page.dart';
import 'routes.dart';

/// 全局路由。
///
/// 结构：
/// - `/onboarding`（shell 外，全屏）
/// - [StatefulShellRoute]（持有底部 nav，4 个 branch）：
///   - `/weather`（今日）/ `/forecast` / `/wardrobe` / `/settings`
///
/// 冷启动判定：依据 [selectedLocationProvider] 同步快照，
/// 有缓存定位则直接进 `/weather`，否则停在 `/onboarding`。
/// 运行时通过 [refreshListenable] + [redirect] 跟进位置变化（登录/登出/切城市）。
final goRouterProvider = Provider<GoRouter>((ref) {
  final initialLocation = ref.read(selectedLocationProvider);

  // 把 Riverpod 的位置变更桥接成 [Listenable]，让 GoRouter 在变化时重跑 redirect。
  final listenable = ValueNotifier<GeoLocation?>(initialLocation);
  ref.listen<GeoLocation?>(selectedLocationProvider, (_, next) {
    listenable.value = next;
  });
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: initialLocation == null
        ? Routes.onboarding
        : Routes.weatherHome,
    refreshListenable: listenable,
    redirect: (context, state) {
      final hasLocation = listenable.value != null;
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      // 城市搜索是 onboarding 选位置的入口之一，未选定时也必须可达。
      final atCitySearch = state.matchedLocation == Routes.citySearch;
      if (!hasLocation && !atOnboarding && !atCitySearch) {
        return Routes.onboarding;
      }
      if (hasLocation && atOnboarding) return Routes.weatherHome;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.citySearch,
        builder: (context, state) => const CitySearchPage(),
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
