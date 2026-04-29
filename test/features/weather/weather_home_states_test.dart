import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/core/error/app_exception.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/features/weather/model/current_weather.dart';
import 'package:weather_app/features/weather/model/geo_location.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';
import 'package:weather_app/features/weather/model/weather_forecast.dart';
import 'package:weather_app/features/weather/repository/open_meteo_repository.dart';
import 'package:weather_app/features/weather/repository/weather_repository.dart';

/// 可控的假仓库——每次 [fetchForecast] 调用 [_factory] 取下一个 future，
/// 可在测试里随意抛错或返回数据。
class _ScriptedWeatherRepository implements WeatherRepository {
  _ScriptedWeatherRepository(this._factory);

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

WeatherForecast _sampleForecast() {
  return WeatherForecast(
    timezone: 'Asia/Shanghai',
    current: CurrentWeather(
      time: DateTime.utc(2026, 4, 29, 9),
      temperatureC: 22,
      apparentTemperatureC: 21,
      humidityPct: 60,
      precipitationMm: 0,
      isDay: true,
      condition: WeatherCondition.partlyCloudy,
      windSpeedKmh: 10,
      windDirectionDeg: 90,
    ),
    daily: const [],
  );
}

/// 用 Pro Max 级宽度——避免 [_WeatherChipsRow] 在 390 宽下的横向溢出。
/// （那是另一个 figma 还原层面的 layout bug，本任务不修。）
void _setPhoneViewport(WidgetTester tester) {
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

void main() {
  testWidgets('shows loading view while forecast is pending', (tester) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedWeatherRepository(
      () => Completer<WeatherForecast>().future,
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在获取天气…'), findsOneWidget);
  });

  testWidgets('shows friendly error + retry on NetworkException', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedWeatherRepository(
      () => Future<WeatherForecast>.error(
        const NetworkException('boom', statusCode: 500),
      ),
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump(); // first build (loading)
    await tester.pump(); // future completes → error

    // 用户友好文案，不暴露原始异常字符串。
    expect(find.text('网络出错（500），请稍后重试'), findsOneWidget);
    expect(find.text('boom'), findsNothing);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('retry button refetches the forecast', (tester) async {
    _setPhoneViewport(tester);
    var fail = true;
    final repo = _ScriptedWeatherRepository(() {
      if (fail) {
        return Future<WeatherForecast>.error(
          const NetworkException('temporary'),
        );
      }
      return Future<WeatherForecast>.value(_sampleForecast());
    });
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();
    expect(find.text('重试'), findsOneWidget);
    expect(repo.callCount, 1);

    fail = false;
    await tester.tap(find.text('重试'));
    await tester.pump(); // invalidate → loading
    await tester.pump(); // future resolves → data

    // 加载成功后温度数字会出现在主内容里。
    expect(find.text('22°C'), findsOneWidget);
    expect(repo.callCount, 2);
  });

  testWidgets('uses fallback message for unknown errors', (tester) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedWeatherRepository(
      () => Future<WeatherForecast>.error(Exception('something weird')),
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();

    expect(find.text('出了点问题，请稍后再试'), findsOneWidget);
  });

  testWidgets('pull-to-refresh refetches the forecast', (tester) async {
    _setPhoneViewport(tester);
    final repo = _ScriptedWeatherRepository(
      () => Future<WeatherForecast>.value(_sampleForecast()),
    );
    await tester.pumpWidget(await _appWith(repo: repo));
    await tester.pump();
    await tester.pump();

    expect(find.text('22°C'), findsOneWidget);
    expect(repo.callCount, 1);

    // 下拉触发 RefreshIndicator——从天气卡顶部往下拖动 300 像素。
    final scrollable = find.byType(SingleChildScrollView).first;
    await tester.drag(scrollable, const Offset(0, 300));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.callCount, greaterThanOrEqualTo(2));
  });
}
