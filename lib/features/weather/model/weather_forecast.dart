import 'package:flutter/foundation.dart';

import 'current_weather.dart';
import 'daily_forecast.dart';

/// 一次天气查询的完整结果聚合。
@immutable
class WeatherForecast {
  const WeatherForecast({
    required this.timezone,
    required this.current,
    required this.daily,
  });

  final String timezone;
  final CurrentWeather current;
  final List<DailyForecast> daily;

  factory WeatherForecast.fromCacheJson(Map<String, dynamic> json) {
    return WeatherForecast(
      timezone: json['timezone'] as String,
      current: CurrentWeather.fromCacheJson(
        (json['current'] as Map).cast<String, dynamic>(),
      ),
      daily: (json['daily'] as List)
          .cast<Map>()
          .map((m) => DailyForecast.fromCacheJson(m.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  Map<String, Object?> toCacheJson() => {
        'timezone': timezone,
        'current': current.toCacheJson(),
        'daily': daily.map((d) => d.toCacheJson()).toList(growable: false),
      };
}
