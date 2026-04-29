import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/core/units/units.dart';
import 'package:weather_app/features/settings/controller/preferences_provider.dart';
import 'package:weather_app/features/settings/model/user_preferences.dart';
import 'package:weather_app/features/weather/model/current_weather.dart';
import 'package:weather_app/features/weather/model/geo_location.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';
import 'package:weather_app/features/weather/model/weather_forecast.dart';
import 'package:weather_app/features/weather/repository/open_meteo_repository.dart';
import 'package:weather_app/features/weather/repository/weather_repository.dart';

class _StubRepo implements WeatherRepository {
  _StubRepo(this._forecast);
  final WeatherForecast _forecast;

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
  }) => Future.value(_forecast);
}

WeatherForecast _forecast() {
  // 20°C ↔ 68°F；36 km/h ↔ 10.0 m/s——便于断言。
  return WeatherForecast(
    timezone: 'Asia/Shanghai',
    current: CurrentWeather(
      time: DateTime.utc(2026, 4, 29, 9),
      temperatureC: 20,
      apparentTemperatureC: 20,
      humidityPct: 50,
      precipitationMm: 0,
      isDay: true,
      condition: WeatherCondition.partlyCloudy,
      windSpeedKmh: 36,
      windDirectionDeg: 90,
    ),
    daily: const [],
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

Future<Widget> _appWith(Map<String, Object> seed) async {
  // 注入位置缓存——避免被 onboarding 拦下，直接进 home。
  const cached = GeoLocation(name: '上海', latitude: 31.23, longitude: 121.47);
  SharedPreferences.setMockInitialValues(<String, Object>{
    'selected_location.v1': jsonEncode(cached.toJson()),
    ...seed,
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(_StubRepo(_forecast())),
    ],
    child: const WeatherApp(),
  );
}

void main() {
  testWidgets('home shows celsius + km/h by default', (tester) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(await _appWith(const <String, Object>{}));
    await tester.pump();
    await tester.pump();

    expect(find.text('20°C'), findsOneWidget);
    expect(find.text('体感 20°C'), findsOneWidget);
    // 风向 90° → 东风
    expect(find.text('东风 36 km/h'), findsOneWidget);
  });

  testWidgets(
    'home switches to fahrenheit + m/s when prefs are persisted that way',
    (tester) async {
      _setPhoneViewport(tester);
      const prefsJson = UserPreferences(
        temperatureUnit: TemperatureUnit.fahrenheit,
        windSpeedUnit: WindSpeedUnit.ms,
      );
      final encoded = jsonEncode(prefsJson.toJson());
      await tester.pumpWidget(
        await _appWith(<String, Object>{'user_preferences.v1': encoded}),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('68°F'), findsOneWidget);
      expect(find.text('体感 68°F'), findsOneWidget);
      expect(find.text('东风 10.0 m/s'), findsOneWidget);
    },
  );

  testWidgets('changing units at runtime updates the display', (tester) async {
    _setPhoneViewport(tester);
    const cached = GeoLocation(name: '上海', latitude: 31.23, longitude: 121.47);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'selected_location.v1': jsonEncode(cached.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        weatherRepositoryProvider.overrideWithValue(_StubRepo(_forecast())),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const WeatherApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 默认：°C
    expect(find.text('20°C'), findsOneWidget);

    // 通过持有的 container 模拟设置页的 setter——对运行时切换更稳。
    container
        .read(userPreferencesProvider.notifier)
        .setTemperatureUnit(TemperatureUnit.fahrenheit);
    await tester.pump();

    expect(find.text('20°C'), findsNothing);
    expect(find.text('68°F'), findsOneWidget);
  });
}
