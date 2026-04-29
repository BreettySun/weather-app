import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/features/onboarding/view/onboarding_page.dart';
import 'package:weather_app/features/weather/model/geo_location.dart';
import 'package:weather_app/features/weather/model/weather_forecast.dart';
import 'package:weather_app/features/weather/repository/open_meteo_repository.dart';
import 'package:weather_app/features/weather/repository/weather_repository.dart';
import 'package:weather_app/features/weather/view/weather_home_page.dart';

/// 路由测试用 fake——返回永不完成的 future，避免触发真实网络。
/// `forecastProvider` 调用它后停在 loading 态，UI 仍然走到 [WeatherHomePage]。
class _FakeWeatherRepository implements WeatherRepository {
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
  }) => Completer<WeatherForecast>().future;
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<Widget> _appWith(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(_FakeWeatherRepository()),
    ],
    child: const WeatherApp(),
  );
}

void main() {
  testWidgets(
    'cold start without cached location lands on OnboardingPage',
    (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(await _appWith(<String, Object>{}));
      await tester.pump();

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(WeatherHomePage), findsNothing);
    },
  );

  testWidgets(
    'cold start with cached location skips onboarding',
    (tester) async {
      _setPhoneViewport(tester);
      const cached = GeoLocation(
        name: '上海',
        latitude: 31.23,
        longitude: 121.47,
        country: '中国',
      );
      await tester.pumpWidget(
        await _appWith(<String, Object>{
          'selected_location.v1': jsonEncode(cached.toJson()),
        }),
      );
      await tester.pump();

      expect(find.byType(WeatherHomePage), findsOneWidget);
      expect(find.byType(OnboardingPage), findsNothing);
    },
  );
}
