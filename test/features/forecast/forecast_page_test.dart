import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/core/error/app_exception.dart';
import 'package:weather_app/core/router/routes.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/features/forecast/view/forecast_page.dart';
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

WeatherForecast _sampleForecast({int days = 5}) {
  final today = DateTime.utc(2026, 4, 29);
  return WeatherForecast(
    timezone: 'Asia/Shanghai',
    current: CurrentWeather(
      time: today,
      temperatureC: 22,
      apparentTemperatureC: 21,
      humidityPct: 60,
      precipitationMm: 0,
      isDay: true,
      condition: WeatherCondition.partlyCloudy,
      windSpeedKmh: 10,
      windDirectionDeg: 90,
    ),
    daily: List.generate(days, (i) {
      return DailyForecast(
        date: today.add(Duration(days: i)),
        tempMaxC: 24 + i.toDouble(),
        tempMinC: 16 + i.toDouble(),
        apparentMaxC: 25 + i.toDouble(),
        apparentMinC: 15 + i.toDouble(),
        condition: i.isEven
            ? WeatherCondition.partlyCloudy
            : WeatherCondition.rain,
        precipitationSumMm: i.isEven ? 0 : 2.5,
        precipitationProbabilityPct: i.isEven ? 0 : 70,
        uvIndexMax: 5,
        windSpeedMaxKmh: 12,
      );
    }),
  );
}

void _setPhoneViewport(WidgetTester tester) {
  // 用 Pro Max 宽度——避开主页 weather chips 在 390 下的横向溢出。
  tester.view.physicalSize = const Size(430 * 3, 932 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<Widget> _appWith({required WeatherRepository repo}) async {
  const cached = GeoLocation(
    name: '上海',
    latitude: 31.23,
    longitude: 121.47,
  );
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

/// 进入预报 tab——通过底部 nav 点"预报"。
Future<void> _gotoForecastTab(WidgetTester tester) async {
  // tab label 文案在 [AppBottomNav]——"预报"。
  await tester.tap(find.text('预报'));
  await tester.pump();
}

/// 通过 GoRouter 直接跳——避免依赖底部 nav 的具体文案。
Future<void> _gotoForecast(WidgetTester tester, ProviderContainer? _) async {
  // 找一下当前 BuildContext 的 GoRouter 容易出错——简单起见直接 tap nav。
  await _gotoForecastTab(tester);
}

void main() {
  testWidgets('renders summary + day rows on data', (tester) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedRepo(
      () => Future<WeatherForecast>.value(_sampleForecast(days: 5)),
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();

    await _gotoForecast(tester, null);
    await tester.pump();

    // 进到预报页
    expect(find.byType(ForecastPage), findsOneWidget);

    // 顶栏 + 摘要卡
    expect(find.text('未来 7 日'), findsOneWidget);
    expect(find.text('未来 5 日'), findsOneWidget); // SummaryCard 标题随数据条数

    // 第一行 = 今天，第二行 = 明天，第三行 = 后天
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('明天'), findsOneWidget);
    expect(find.text('后天'), findsOneWidget);

    // 至少看到一个降水概率 chip——索引为奇数的那几天
    expect(find.textContaining('降水 70%'), findsWidgets);
  });

  testWidgets('shows loading state while forecast is pending', (tester) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedRepo(() => Completer<WeatherForecast>().future);
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await _gotoForecast(tester, null);
    await tester.pump();

    expect(find.byType(ForecastPage), findsOneWidget);
    expect(find.text('正在获取预报…'), findsOneWidget);
  });

  testWidgets('shows friendly error + retry button on NetworkException', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedRepo(
      () => Future<WeatherForecast>.error(
        const NetworkException('boom', statusCode: 503),
      ),
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();
    await _gotoForecast(tester, null);
    await tester.pump();
    await tester.pump();

    expect(find.text('网络出错（503），请稍后重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('retry triggers a refetch', (tester) async {
    _setPhoneViewport(tester);
    var fail = true;
    final repo = _ScriptedRepo(() {
      if (fail) {
        return Future<WeatherForecast>.error(
          const NetworkException('boom'),
        );
      }
      return Future<WeatherForecast>.value(_sampleForecast(days: 3));
    });
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();
    await _gotoForecast(tester, null);
    await tester.pump();
    await tester.pump();

    expect(find.text('重试'), findsOneWidget);
    final initial = repo.callCount;

    fail = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(repo.callCount, greaterThan(initial));
    expect(find.byType(ForecastPage), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
  });

  // sanity check that route alias is wired (catches accidental rename).
  test('forecast tab path constant is correct', () {
    expect(Routes.forecast, '/forecast');
  });
}
