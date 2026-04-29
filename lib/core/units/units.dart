/// 单位枚举与显示层格式化工具——天气数据在内部统一保存为 °C / km/h，
/// 仅在最终展示时按用户偏好转换。
library;

/// 温度单位。
enum TemperatureUnit {
  celsius('°C', '摄氏度'),
  fahrenheit('°F', '华氏度');

  const TemperatureUnit(this.symbol, this.label);

  final String symbol;
  final String label;
}

/// 风速单位。
enum WindSpeedUnit {
  kmh('km/h', '公里/小时'),
  ms('m/s', '米/秒');

  const WindSpeedUnit(this.symbol, this.label);

  final String symbol;
  final String label;
}

/// 把摄氏度转换到目标单位的数值（不包含单位符号）。
double convertCelsius(double c, TemperatureUnit unit) {
  return switch (unit) {
    TemperatureUnit.celsius => c,
    TemperatureUnit.fahrenheit => c * 9 / 5 + 32,
  };
}

/// 把 km/h 转换到目标单位的数值。
double convertKmh(double kmh, WindSpeedUnit unit) {
  return switch (unit) {
    WindSpeedUnit.kmh => kmh,
    WindSpeedUnit.ms => kmh / 3.6,
  };
}

/// `21°C` / `70°F`——含单位符号，适合首要展示位。
String formatTemperature(double celsius, TemperatureUnit unit) {
  final v = convertCelsius(celsius, unit).round();
  return '$v${unit.symbol}';
}

/// `21°` / `70°`——只带角度符号，适合紧凑场景（min/max 区间、3 日小预报等）。
String formatTemperatureShort(double celsius, TemperatureUnit unit) {
  final v = convertCelsius(celsius, unit).round();
  return '$v°';
}

/// `12 km/h` / `3 m/s`——km/h 整数；m/s 数值小，保留 1 位小数。
String formatWindSpeed(double kmh, WindSpeedUnit unit) {
  final v = convertKmh(kmh, unit);
  final str = switch (unit) {
    WindSpeedUnit.kmh => v.round().toString(),
    WindSpeedUnit.ms => v.toStringAsFixed(1),
  };
  return '$str ${unit.symbol}';
}
