import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/error/app_exception.dart';
import 'package:weather_app/core/storage/preferences.dart';
import 'package:weather_app/features/weather/controller/forecast_provider.dart';
import 'package:weather_app/features/weather/controller/location_provider.dart';
import 'package:weather_app/features/weather/model/current_weather.dart';
import 'package:weather_app/features/weather/model/daily_forecast.dart';
import 'package:weather_app/features/weather/model/geo_location.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';
import 'package:weather_app/features/weather/model/weather_forecast.dart';
import 'package:weather_app/features/weather/repository/forecast_cache.dart';
import 'package:weather_app/features/weather/repository/open_meteo_repository.dart';
import 'package:weather_app/features/weather/repository/weather_repository.dart';

class _StubRepo implements WeatherRepository {
  _StubRepo(this._next);
  final Future<WeatherForecast> Function() _next;
  int calls = 0;

  @override
  Future<List<GeoLocation>> searchCity(
    String q, {
    String language = 'zh',
    int count = 10,
  }) async => const [];

  @override
  Future<WeatherForecast> fetchForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
    String? timezone,
  }) {
    calls++;
    return _next();
  }
}

WeatherForecast _forecast({double tempC = 22}) => WeatherForecast(
      timezone: 'Asia/Shanghai',
      current: CurrentWeather(
        time: DateTime.utc(2026, 4, 30, 9),
        temperatureC: tempC,
        apparentTemperatureC: tempC - 1,
        humidityPct: 55,
        precipitationMm: 0,
        condition: WeatherCondition.clear,
        windSpeedKmh: 8,
        windDirectionDeg: 90,
        isDay: true,
      ),
      daily: [
        DailyForecast(
          date: DateTime.utc(2026, 4, 30),
          tempMaxC: tempC + 4,
          tempMinC: tempC - 4,
          apparentMaxC: tempC + 3,
          apparentMinC: tempC - 5,
          condition: WeatherCondition.clear,
          precipitationSumMm: 0,
          precipitationProbabilityPct: 10,
          uvIndexMax: 6,
          windSpeedMaxKmh: 15,
        ),
      ],
    );

const _location = GeoLocation(
  name: '上海',
  latitude: 31.23,
  longitude: 121.47,
);

Future<ProviderContainer> _container({
  required WeatherRepository repo,
  Map<String, Object> initialPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(repo),
    ],
  );
  // 主动设置位置，让 forecastProvider 不至于因为没位置直接抛 StateError。
  container.read(selectedLocationProvider.notifier).set(_location);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForecastCache JSON 往返', () {
    test('write 后 read 能还原结构', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final cache = ForecastCache(prefs);

      final original = _forecast(tempC: 18);
      await cache.write(forecast: original, location: _location);

      final restored = cache.read();
      expect(restored, isNotNull);
      expect(restored!.matches(_location), isTrue);
      expect(restored.forecast.timezone, original.timezone);
      expect(restored.forecast.current.temperatureC, 18);
      expect(restored.forecast.current.condition, WeatherCondition.clear);
      expect(restored.forecast.daily.length, 1);
      expect(restored.forecast.daily.first.tempMaxC, 22);
    });

    test('read 遇到坏 JSON 时不抛错并清掉脏值', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'forecast_cache.v2': '{not valid json',
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = ForecastCache(prefs);

      expect(cache.read(), isNull);
      expect(prefs.getString('forecast_cache.v2'), isNull);
    });

    test('v1 payload 在升级后被忽略（按"无缓存"走）', () async {
      // 升级前的 v1 payload，结构不含 hourly。新版本不读 v1 key，应得到 null。
      SharedPreferences.setMockInitialValues(<String, Object>{
        'forecast_cache.v1': '{"forecast":{"timezone":"X"},"latitude":0}',
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = ForecastCache(prefs);
      expect(cache.read(), isNull);
    });
  });

  group('forecastProvider 缓存合流策略', () {
    test('网络成功后缓存被刷新', () async {
      final repo = _StubRepo(() async => _forecast(tempC: 25));
      final container = await _container(repo: repo);
      addTearDown(container.dispose);

      final result = await container.read(forecastProvider.future);
      expect(result.current.temperatureC, 25);
      // 让 microtask 跑完，等 cache.write 落盘。
      await Future<void>.delayed(Duration.zero);
      final cached = container.read(forecastCacheProvider).read();
      expect(cached, isNotNull);
      expect(cached!.forecast.current.temperatureC, 25);
    });

    test('断网时回退到本地缓存（不进 error 态）', () async {
      // 预先把"昨天"的预报塞进 SharedPreferences。
      SharedPreferences.setMockInitialValues(const {});
      final seedPrefs = await SharedPreferences.getInstance();
      await ForecastCache(seedPrefs)
          .write(forecast: _forecast(tempC: 12), location: _location);

      final repo = _StubRepo(
        () async => throw const NetworkException('offline'),
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(seedPrefs),
          weatherRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.read(selectedLocationProvider.notifier).set(_location);

      // 不 await `.future`——它会拿到最后一个值（即抛错时是 future error），
      // 我们想验证 watch 流的最后一个 *data* 状态。直接跑两次 microtask 等流走完。
      final values = <double>[];
      final sub = container.listen<AsyncValue<WeatherForecast>>(
        forecastProvider,
        (_, next) {
          final v = next.valueOrNull?.current.temperatureC;
          if (v != null) values.add(v);
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // 让 stream 跑：先 yield cache，再 await repo 报错，再吞错。
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(values, contains(12.0));
      expect(repo.calls, 1);
      // 终态是 AsyncData(cache)——不是 error。
      final state = container.read(forecastProvider);
      expect(state, isA<AsyncData<WeatherForecast>>());
      expect(state.value!.current.temperatureC, 12);
    });

    test('网络失败且无缓存时进 error 态', () async {
      final repo = _StubRepo(
        () async => throw const NetworkException('timeout'),
      );
      final container = await _container(repo: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(forecastProvider.future),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
