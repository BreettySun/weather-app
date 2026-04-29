import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/core/error/app_exception.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/features/wardrobe/view/wardrobe_page.dart';
import 'package:weather_app/features/weather/model/current_weather.dart';
import 'package:weather_app/features/weather/model/daily_forecast.dart';
import 'package:weather_app/features/weather/model/geo_location.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';
import 'package:weather_app/features/weather/model/weather_forecast.dart';
import 'package:weather_app/features/weather/repository/open_meteo_repository.dart';
import 'package:weather_app/features/weather/repository/weather_repository.dart';

class _ScriptedRepo implements WeatherRepository {
  _ScriptedRepo(this._factory);

  final Future<WeatherForecast> Function() _factory;
  int callCount = 0;

  @override
  Future<List<GeoLocation>> searchCity(
    String query, {
    String language = 'zh',
    int count = 10,
  }) => Completer<List<GeoLocation>>().future;

  @override
  Future<WeatherForecast> fetchForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
    String? timezone,
  }) {
    callCount++;
    return _factory();
  }
}

WeatherForecast _forecastWithFeels(double feels) {
  final today = DateTime.utc(2026, 4, 29);
  return WeatherForecast(
    timezone: 'Asia/Shanghai',
    current: CurrentWeather(
      time: today,
      temperatureC: feels + 1,
      apparentTemperatureC: feels,
      humidityPct: 60,
      precipitationMm: 0,
      isDay: true,
      condition: WeatherCondition.partlyCloudy,
      windSpeedKmh: 10,
      windDirectionDeg: 90,
    ),
    daily: [
      DailyForecast(
        date: today,
        tempMaxC: feels + 4,
        tempMinC: feels - 4,
        apparentMaxC: feels + 4,
        apparentMinC: feels - 4,
        condition: WeatherCondition.partlyCloudy,
        precipitationSumMm: 0,
        precipitationProbabilityPct: 10,
        uvIndexMax: 3,
        windSpeedMaxKmh: 12,
      ),
    ],
  );
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430 * 3, 932 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<Widget> _appWith({required WeatherRepository repo}) async {
  const cached = GeoLocation(name: '上海', latitude: 31.23, longitude: 121.47);
  SharedPreferences.setMockInitialValues(<String, Object>{
    'selected_location.v1': jsonEncode(cached.toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(repo),
    ],
    child: const WeatherApp(),
  );
}

Future<void> _gotoWardrobe(WidgetTester tester) async {
  await tester.tap(find.text('衣橱'));
  await tester.pump();
}

void main() {
  testWidgets('renders all 6 brackets and highlights the matching one', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    // 体感 18° 落在"温和 15°–22°"档。
    final repo = _ScriptedRepo(
      () => Future<WeatherForecast>.value(_forecastWithFeels(18)),
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();
    await _gotoWardrobe(tester);
    await tester.pump();

    expect(find.byType(WardrobePage), findsOneWidget);

    // 6 档全部渲染——靠下的档位可能在 cache 之外，用 skipOffstage:false 全量查找。
    expect(find.text('严寒', skipOffstage: false), findsOneWidget);
    expect(find.text('寒冷', skipOffstage: false), findsOneWidget);
    expect(find.text('凉爽', skipOffstage: false), findsOneWidget);
    expect(find.text('温和', skipOffstage: false), findsOneWidget);
    expect(find.text('温暖', skipOffstage: false), findsOneWidget);
    expect(find.text('炎热', skipOffstage: false), findsOneWidget);

    // 体感 18° → 仅"温和"档显示"当前"徽标
    expect(find.text('当前', skipOffstage: false), findsOneWidget);

    // 今日推荐卡显示体感温度
    expect(find.text('体感 18°'), findsOneWidget);
  });

  testWidgets('renders reference table even without forecast (loading)', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedRepo(() => Completer<WeatherForecast>().future);
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await _gotoWardrobe(tester);
    await tester.pump();

    // 即使在 loading 也要展示 6 档参考——核心价值与网络无关。
    expect(find.text('严寒', skipOffstage: false), findsOneWidget);
    expect(find.text('炎热', skipOffstage: false), findsOneWidget);
    // 没数据时不高亮任何一档
    expect(find.text('当前', skipOffstage: false), findsNothing);
  });

  testWidgets('shows inline error banner with retry on fetch failure', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedRepo(
      () => Future<WeatherForecast>.error(
        const NetworkException('boom', statusCode: 500),
      ),
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();
    await _gotoWardrobe(tester);
    await tester.pump();
    await tester.pump();

    // 错误条带——但参考表照常显示。
    // 错误条占了顶部空间，"炎热"可能滚出 cache 范围，用 skipOffstage:false 兜底。
    expect(find.textContaining('网络出错（500）'), findsOneWidget);
    expect(find.text('严寒', skipOffstage: false), findsOneWidget);
    expect(find.text('炎热', skipOffstage: false), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('cold weather highlights 严寒 bracket', (tester) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedRepo(
      () => Future<WeatherForecast>.value(_forecastWithFeels(-3)),
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();
    await _gotoWardrobe(tester);
    await tester.pump();

    expect(find.text('体感 -3°'), findsOneWidget);
    expect(find.text('当前', skipOffstage: false), findsOneWidget);
  });
}
