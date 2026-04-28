import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/model/daily_forecast.dart';
import 'package:weather_app/features/weather/model/weather_condition.dart';

void main() {
  group('parseDailyForecasts', () {
    test('zips parallel arrays into DailyForecast list with matching length', () {
      final daily = <String, dynamic>{
        'time': ['2026-04-28', '2026-04-29'],
        'temperature_2m_max': [22.1, 24.3],
        'temperature_2m_min': [12.4, 14.0],
        'apparent_temperature_max': [21.0, 23.0],
        'apparent_temperature_min': [11.0, 13.0],
        'weather_code': [3, 61],
        'precipitation_sum': [0.0, 4.2],
        'precipitation_probability_max': [10, 80],
        'uv_index_max': [5.0, 4.0],
        'wind_speed_10m_max': [12.0, 18.0],
        'sunrise': ['2026-04-28T05:30', '2026-04-29T05:29'],
        'sunset': ['2026-04-28T18:40', '2026-04-29T18:41'],
      };

      final forecasts = parseDailyForecasts(daily);

      expect(forecasts, hasLength(2));
      expect(forecasts[0].date, DateTime(2026, 4, 28));
      expect(forecasts[0].tempMaxC, 22.1);
      expect(forecasts[0].condition, WeatherCondition.overcast);
      expect(forecasts[1].condition, WeatherCondition.rain);
      expect(forecasts[1].precipitationProbabilityPct, 80);
      expect(forecasts[1].sunrise, isNotNull);
    });

    test('tolerates missing optional arrays (precipitation, uv, wind, sunrise)', () {
      final daily = <String, dynamic>{
        'time': ['2026-04-28'],
        'temperature_2m_max': [20.0],
        'temperature_2m_min': [10.0],
        'apparent_temperature_max': [19.0],
        'apparent_temperature_min': [9.0],
        'weather_code': [0],
      };

      final forecasts = parseDailyForecasts(daily);

      expect(forecasts, hasLength(1));
      expect(forecasts[0].condition, WeatherCondition.clear);
      expect(forecasts[0].precipitationSumMm, 0);
      expect(forecasts[0].uvIndexMax, 0);
      expect(forecasts[0].sunrise, isNull);
    });
  });
}
