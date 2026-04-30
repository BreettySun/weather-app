import 'package:flutter/foundation.dart';

import 'weather_condition.dart';

/// 当前实时天气。字段为单位归一化后的常规标量值。
@immutable
class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.humidityPct,
    required this.precipitationMm,
    required this.condition,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.isDay,
  });

  final DateTime time;
  final double temperatureC;
  final double apparentTemperatureC;
  final int humidityPct;
  final double precipitationMm;
  final WeatherCondition condition;
  final double windSpeedKmh;
  final int windDirectionDeg;
  final bool isDay;

  /// 解析 Open-Meteo `/v1/forecast` 响应中的 `current` 段。
  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: DateTime.parse(json['time'] as String),
      temperatureC: (json['temperature_2m'] as num).toDouble(),
      apparentTemperatureC: (json['apparent_temperature'] as num).toDouble(),
      humidityPct: (json['relative_humidity_2m'] as num).toInt(),
      precipitationMm: (json['precipitation'] as num? ?? 0).toDouble(),
      condition: WeatherCondition.fromCode(json['weather_code'] as int?),
      windSpeedKmh: (json['wind_speed_10m'] as num? ?? 0).toDouble(),
      windDirectionDeg: (json['wind_direction_10m'] as num? ?? 0).toInt(),
      isDay: (json['is_day'] as int? ?? 1) == 1,
    );
  }

  /// 缓存反序列化——键名与字段一一对应，与 Open-Meteo 网络格式分离，
  /// 避免缓存版本耦合到第三方接口字段名。
  factory CurrentWeather.fromCacheJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: DateTime.parse(json['time'] as String),
      temperatureC: (json['temperatureC'] as num).toDouble(),
      apparentTemperatureC: (json['apparentTemperatureC'] as num).toDouble(),
      humidityPct: (json['humidityPct'] as num).toInt(),
      precipitationMm: (json['precipitationMm'] as num).toDouble(),
      condition: WeatherCondition.values.byName(json['condition'] as String),
      windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
      windDirectionDeg: (json['windDirectionDeg'] as num).toInt(),
      isDay: json['isDay'] as bool,
    );
  }

  Map<String, Object?> toCacheJson() => {
        'time': time.toIso8601String(),
        'temperatureC': temperatureC,
        'apparentTemperatureC': apparentTemperatureC,
        'humidityPct': humidityPct,
        'precipitationMm': precipitationMm,
        'condition': condition.name,
        'windSpeedKmh': windSpeedKmh,
        'windDirectionDeg': windDirectionDeg,
        'isDay': isDay,
      };
}
