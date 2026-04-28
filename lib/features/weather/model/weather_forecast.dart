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
}
