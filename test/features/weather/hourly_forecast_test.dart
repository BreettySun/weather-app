import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/model/hourly_forecast.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';

void main() {
  group('parseHourlyForecasts', () {
    test('展开平行数组', () {
      final list = parseHourlyForecasts(const {
        'time': ['2026-04-30T00:00', '2026-04-30T01:00'],
        'temperature_2m': [12.5, 12.0],
        'apparent_temperature': [10.0, 9.5],
        'weather_code': [0, 3],
        'precipitation_probability': [10, 20],
        'wind_speed_10m': [5.0, 7.0],
      });
      expect(list, hasLength(2));
      expect(list[0].time, DateTime.parse('2026-04-30T00:00'));
      expect(list[0].temperatureC, 12.5);
      expect(list[0].condition, WeatherCondition.clear);
      expect(list[1].condition, WeatherCondition.overcast);
      expect(list[1].precipitationProbabilityPct, 20);
    });

    test('缺省可选字段时使用 0', () {
      final list = parseHourlyForecasts(const {
        'time': ['2026-04-30T00:00'],
        'temperature_2m': [10.0],
        'apparent_temperature': [9.0],
        'weather_code': [0],
        // 故意缺 precipitation_probability / wind_speed_10m
      });
      expect(list, hasLength(1));
      expect(list[0].precipitationProbabilityPct, 0);
      expect(list[0].windSpeedKmh, 0);
    });
  });

  test('cache JSON round-trip', () {
    final h = HourlyForecast(
      time: DateTime.parse('2026-04-30T14:00:00.000Z'),
      temperatureC: 18.5,
      apparentTemperatureC: 17.0,
      condition: WeatherCondition.partlyCloudy,
      precipitationProbabilityPct: 30,
      windSpeedKmh: 12.5,
    );
    final restored = HourlyForecast.fromCacheJson(
      Map<String, dynamic>.from(h.toCacheJson()),
    );
    expect(restored.time, h.time);
    expect(restored.temperatureC, 18.5);
    expect(restored.condition, WeatherCondition.partlyCloudy);
    expect(restored.precipitationProbabilityPct, 30);
    expect(restored.windSpeedKmh, 12.5);
  });
}
