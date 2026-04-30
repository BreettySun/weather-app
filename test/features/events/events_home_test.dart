import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/features/events/controller/events_provider.dart';
import 'package:weather_app/features/events/model/activity.dart';
import 'package:weather_app/features/events/model/day_event.dart';
import 'package:weather_app/features/weather/model/current_weather.dart';
import 'package:weather_app/features/weather/model/daily_forecast.dart';
import 'package:weather_app/features/weather/model/geo_location.dart';
import 'package:weather_app/features/weather/model/hourly_forecast.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';
import 'package:weather_app/features/weather/model/weather_forecast.dart';
import 'package:weather_app/features/weather/repository/open_meteo_repository.dart';
import 'package:weather_app/features/weather/repository/weather_repository.dart';

class _StubRepo implements WeatherRepository {
  _StubRepo(this._forecast);
  final WeatherForecast _forecast;

  @override
  Future<List<GeoLocation>> searchCity(String q,
          {String language = 'zh', int count = 10}) async =>
      const [];

  @override
  Future<WeatherForecast> fetchForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
    String? timezone,
  }) async =>
      _forecast;
}

WeatherForecast _sample() {
  final now = DateTime.now();
  return WeatherForecast(
    timezone: 'Asia/Shanghai',
    current: CurrentWeather(
      time: now,
      temperatureC: 22,
      apparentTemperatureC: 21,
      humidityPct: 50,
      precipitationMm: 0,
      condition: WeatherCondition.partlyCloudy,
      windSpeedKmh: 8,
      windDirectionDeg: 90,
      isDay: true,
    ),
    daily: [
      DailyForecast(
        date: DateTime(now.year, now.month, now.day),
        tempMaxC: 26,
        tempMinC: 18,
        apparentMaxC: 25,
        apparentMinC: 17,
        condition: WeatherCondition.clear,
        precipitationSumMm: 0,
        precipitationProbabilityPct: 5,
        uvIndexMax: 5,
        windSpeedMaxKmh: 10,
      ),
    ],
    hourly: List.generate(24, (i) {
      return HourlyForecast(
        time: DateTime(now.year, now.month, now.day, i),
        temperatureC: 20 + (i % 5).toDouble(),
        apparentTemperatureC: 19 + (i % 5).toDouble(),
        condition: WeatherCondition.partlyCloudy,
        precipitationProbabilityPct: 10,
        windSpeedKmh: 5,
      );
    }),
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

Future<Widget> _harness({Map<String, Object> initialPrefs = const {}}) async {
  final cached = const GeoLocation(
    name: '上海',
    latitude: 31.23,
    longitude: 121.47,
  );
  final seed = <String, Object>{
    'selected_location.v1': jsonEncode(cached.toJson()),
    ...initialPrefs,
  };
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(_StubRepo(_sample())),
    ],
    child: const WeatherApp(),
  );
}

void main() {
  testWidgets('0 事件 → 只有"添加专门安排"入口，没有标题', (tester) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(await _harness());
    await tester.pumpAndSettle();

    expect(find.text('添加专门安排'), findsOneWidget);
    expect(find.text('今日安排'), findsNothing);
  });

  testWidgets('已存在事件时显示标题 + 卡片', (tester) async {
    _setPhoneViewport(tester);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final payload = jsonEncode({
      'date': today.toIso8601String(),
      'events': [
        DayEvent(
          id: 'e1',
          activity: Activity.outing,
          startAt: today.add(const Duration(hours: 14)),
          note: '爬山',
        ).toJson(),
      ],
    });
    await tester.pumpWidget(await _harness(
      initialPrefs: <String, Object>{'day_events.v1': payload},
    ));
    await tester.pumpAndSettle();

    expect(find.text('今日安排'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('出游'), findsOneWidget);
    // 折叠摘要里有"徒步鞋"（outing 在 mild bracket 的覆盖）
    expect(find.textContaining('徒步鞋'), findsAtLeastNWidgets(1));
  });

  testWidgets('controller.remove → 卡片从首页消失', (tester) async {
    // 不直接做手势——Dismissible 在 widget test 里需要 fling threshold；
    // 改为通过 controller 调用 remove，验证 UI 响应。
    _setPhoneViewport(tester);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final payload = jsonEncode({
      'date': today.toIso8601String(),
      'events': [
        DayEvent(
          id: 'e1',
          activity: Activity.casual,
          startAt: today.add(const Duration(hours: 12)),
        ).toJson(),
      ],
    });
    await tester.pumpWidget(await _harness(
      initialPrefs: <String, Object>{'day_events.v1': payload},
    ));
    await tester.pumpAndSettle();
    expect(find.text('12:00'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.text('添加专门安排')),
    );
    container.read(eventsProvider.notifier).remove('e1');
    await tester.pumpAndSettle();

    expect(find.text('12:00'), findsNothing);
    expect(container.read(eventsProvider), isEmpty);
  });

  testWidgets('点 + 入口弹出 sheet，里面有所有 6 个活动 chip', (tester) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(await _harness());
    await tester.pumpAndSettle();

    // 入口在首页底部，先滚到可视区。
    await tester.ensureVisible(find.text('添加专门安排'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加专门安排'));
    await tester.pumpAndSettle();

    expect(find.text('添加今日安排'), findsOneWidget);
    for (final a in Activity.values) {
      expect(find.textContaining(a.label), findsAtLeastNWidgets(1));
    }
  });
}
