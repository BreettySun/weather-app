import 'package:flutter/foundation.dart';

import 'weather_condition.dart';

/// 单小时预报。Open-Meteo `/v1/forecast` 的 `hourly` 段是平行数组，
/// 用 [parseHourlyForecasts] 一次性展开成本类型列表。
@immutable
class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.condition,
    required this.precipitationProbabilityPct,
    required this.windSpeedKmh,
  });

  final DateTime time;
  final double temperatureC;
  final double apparentTemperatureC;
  final WeatherCondition condition;
  final int precipitationProbabilityPct;
  final double windSpeedKmh;

  /// 缓存反序列化——键名与字段一一对应，与 Open-Meteo 网络字段名解耦。
  factory HourlyForecast.fromCacheJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: DateTime.parse(json['time'] as String),
      temperatureC: (json['temperatureC'] as num).toDouble(),
      apparentTemperatureC: (json['apparentTemperatureC'] as num).toDouble(),
      condition: WeatherCondition.values.byName(json['condition'] as String),
      precipitationProbabilityPct:
          (json['precipitationProbabilityPct'] as num).toInt(),
      windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
    );
  }

  Map<String, Object?> toCacheJson() => {
        'time': time.toIso8601String(),
        'temperatureC': temperatureC,
        'apparentTemperatureC': apparentTemperatureC,
        'condition': condition.name,
        'precipitationProbabilityPct': precipitationProbabilityPct,
        'windSpeedKmh': windSpeedKmh,
      };
}

/// 把 Open-Meteo `hourly` 响应（各字段为平行数组）展开成 [HourlyForecast] 列表。
List<HourlyForecast> parseHourlyForecasts(Map<String, dynamic> hourly) {
  final times = (hourly['time'] as List).cast<String>();
  final temps = (hourly['temperature_2m'] as List).cast<num>();
  final apparent = (hourly['apparent_temperature'] as List).cast<num>();
  final codes = (hourly['weather_code'] as List).cast<num?>();
  final pop = (hourly['precipitation_probability'] as List?)?.cast<num?>() ??
      const [];
  final wind = (hourly['wind_speed_10m'] as List?)?.cast<num?>() ?? const [];

  T? at<T>(List<T?> xs, int i) => i < xs.length ? xs[i] : null;

  return List.generate(times.length, (i) {
    return HourlyForecast(
      time: DateTime.parse(times[i]),
      temperatureC: temps[i].toDouble(),
      apparentTemperatureC: apparent[i].toDouble(),
      condition: WeatherCondition.fromCode(at(codes, i)?.toInt()),
      precipitationProbabilityPct: at(pop, i)?.toInt() ?? 0,
      windSpeedKmh: at(wind, i)?.toDouble() ?? 0,
    );
  });
}
