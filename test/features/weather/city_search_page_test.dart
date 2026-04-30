import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/router/routes.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/features/weather/controller/location_provider.dart';
import 'package:weather_app/features/weather/model/geo_location.dart';
import 'package:weather_app/features/weather/model/weather_forecast.dart';
import 'package:weather_app/features/weather/repository/open_meteo_repository.dart';
import 'package:weather_app/features/weather/repository/weather_repository.dart';
import 'package:weather_app/features/weather/view/city_search_page.dart';

class _StubRepo implements WeatherRepository {
  _StubRepo(this.results);
  List<GeoLocation> results;
  String? lastQuery;

  @override
  Future<List<GeoLocation>> searchCity(
    String query, {
    String language = 'zh',
    int count = 10,
  }) async {
    lastQuery = query;
    return results;
  }

  @override
  Future<WeatherForecast> fetchForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
    String? timezone,
  }) =>
      throw UnimplementedError();
}

Future<Widget> _harness({
  required WeatherRepository repo,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: Routes.citySearch,
    routes: [
      GoRoute(
        path: Routes.citySearch,
        builder: (_, _) => const CitySearchPage(),
      ),
      // 选中后理论上 pop——这里没有上一页可 pop，
      // CitySearchPage 会兜底到 /weather；占位即可。
      GoRoute(
        path: Routes.weatherHome,
        builder: (_, _) => const Scaffold(body: Text('weather-home-stub')),
      ),
    ],
  );
  addTearDown(router.dispose);

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('搜索框输入 → 结果列表渲染', (tester) async {
    final repo = _StubRepo([
      const GeoLocation(
        name: '上海',
        latitude: 31.23,
        longitude: 121.47,
        admin1: '上海市',
        country: '中国',
      ),
      const GeoLocation(
        name: 'Shanghai',
        latitude: 31.0,
        longitude: 121.0,
        country: 'United States',
      ),
    ]);
    await tester.pumpWidget(await _harness(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '上海');
    // 等过 debounce + microtask
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(repo.lastQuery, '上海');
    // 不直接 assert "上海"——TextField 的当前值也是 "上海"，会重叠。
    // 用结果项的副标题（仅在卡片内出现）来锁定。
    expect(find.text('上海市 · 中国'), findsOneWidget);
    expect(find.text('Shanghai'), findsOneWidget);
  });

  testWidgets('点击结果 → 写入 selectedLocationProvider', (tester) async {
    final repo = _StubRepo([
      const GeoLocation(
        name: '北京',
        latitude: 39.9,
        longitude: 116.4,
        country: '中国',
      ),
    ]);
    await tester.pumpWidget(await _harness(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '北京');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // TextField 里的值也是 "北京"，要精确点中结果卡片。
    await tester.tap(find.widgetWithText(InkWell, '北京'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.text('weather-home-stub')),
    );
    expect(container.read(selectedLocationProvider)?.name, '北京');
  });

  testWidgets('空结果时给出友好提示', (tester) async {
    final repo = _StubRepo(const []);
    await tester.pumpWidget(await _harness(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'xyznotacity');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('没有找到匹配的城市'), findsOneWidget);
  });
}
