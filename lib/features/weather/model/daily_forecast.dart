import 'package:flutter/foundation.dart';

import 'weather_condition.dart';

/// 单日预报。
@immutable
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.tempMaxC,
    required this.tempMinC,
    required this.apparentMaxC,
    required this.apparentMinC,
    required this.condition,
    required this.precipitationSumMm,
    required this.precipitationProbabilityPct,
    required this.uvIndexMax,
    required this.windSpeedMaxKmh,
    this.sunrise,
    this.sunset,
  });

  final DateTime date;
  final double tempMaxC;
  final double tempMinC;
  final double apparentMaxC;
  final double apparentMinC;
  final WeatherCondition condition;
  final double precipitationSumMm;
  final int precipitationProbabilityPct;
  final double uvIndexMax;
  final double windSpeedMaxKmh;
  final DateTime? sunrise;
  final DateTime? sunset;
}

/// 把 Open-Meteo 的 `daily` 响应（各字段为平行数组）展开成 [DailyForecast] 列表。
List<DailyForecast> parseDailyForecasts(Map<String, dynamic> daily) {
  final times = (daily['time'] as List).cast<String>();
  final tMax = (daily['temperature_2m_max'] as List).cast<num>();
  final tMin = (daily['temperature_2m_min'] as List).cast<num>();
  final aMax = (daily['apparent_temperature_max'] as List).cast<num>();
  final aMin = (daily['apparent_temperature_min'] as List).cast<num>();
  final codes = (daily['weather_code'] as List).cast<num?>();
  final precip = (daily['precipitation_sum'] as List?)?.cast<num?>() ?? const [];
  final pop = (daily['precipitation_probability_max'] as List?)?.cast<num?>() ?? const [];
  final uv = (daily['uv_index_max'] as List?)?.cast<num?>() ?? const [];
  final windMax = (daily['wind_speed_10m_max'] as List?)?.cast<num?>() ?? const [];
  final sunrise = (daily['sunrise'] as List?)?.cast<String?>() ?? const [];
  final sunset = (daily['sunset'] as List?)?.cast<String?>() ?? const [];

  T? at<T>(List<T?> xs, int i) => i < xs.length ? xs[i] : null;
  DateTime? parseDt(String? s) => s == null ? null : DateTime.tryParse(s);

  return List.generate(times.length, (i) {
    return DailyForecast(
      date: DateTime.parse(times[i]),
      tempMaxC: tMax[i].toDouble(),
      tempMinC: tMin[i].toDouble(),
      apparentMaxC: aMax[i].toDouble(),
      apparentMinC: aMin[i].toDouble(),
      condition: WeatherCondition.fromCode(at(codes, i)?.toInt()),
      precipitationSumMm: at(precip, i)?.toDouble() ?? 0,
      precipitationProbabilityPct: at(pop, i)?.toInt() ?? 0,
      uvIndexMax: at(uv, i)?.toDouble() ?? 0,
      windSpeedMaxKmh: at(windMax, i)?.toDouble() ?? 0,
      sunrise: parseDt(at(sunrise, i)),
      sunset: parseDt(at(sunset, i)),
    );
  });
}
