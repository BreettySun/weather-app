import 'package:flutter/foundation.dart';

import 'current_weather.dart';
import 'daily_forecast.dart';
import 'hourly_forecast.dart';

/// 一次天气查询的完整结果聚合。
@immutable
class WeatherForecast {
  const WeatherForecast({
    required this.timezone,
    required this.current,
    required this.daily,
    this.hourly = const [],
  });

  final String timezone;
  final CurrentWeather current;
  final List<DailyForecast> daily;

  /// 7 天 × 24 小时的小时级预报。可能为空（旧仓库 / 缓存 v1）；
  /// 调用端应做空判断或用 [DailyForecast] 兜底。
  final List<HourlyForecast> hourly;

  factory WeatherForecast.fromCacheJson(Map<String, dynamic> json) {
    final hourlyRaw = json['hourly'] as List?;
    return WeatherForecast(
      timezone: json['timezone'] as String,
      current: CurrentWeather.fromCacheJson(
        (json['current'] as Map).cast<String, dynamic>(),
      ),
      daily: (json['daily'] as List)
          .cast<Map>()
          .map((m) => DailyForecast.fromCacheJson(m.cast<String, dynamic>()))
          .toList(growable: false),
      hourly: hourlyRaw == null
          ? const []
          : hourlyRaw
              .cast<Map>()
              .map((m) => HourlyForecast.fromCacheJson(m.cast<String, dynamic>()))
              .toList(growable: false),
    );
  }

  Map<String, Object?> toCacheJson() => {
        'timezone': timezone,
        'current': current.toCacheJson(),
        'daily': daily.map((d) => d.toCacheJson()).toList(growable: false),
        'hourly': hourly.map((h) => h.toCacheJson()).toList(growable: false),
      };
}
