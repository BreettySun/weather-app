/// WMO 天气代码（Open-Meteo 使用），归并到便于 UI 展示的语义枚举。
///
/// 完整代码表见 https://open-meteo.com/en/docs（"WMO Weather interpretation codes"）。
enum WeatherCondition {
  clear,        // 晴
  mainlyClear,  // 多云转晴
  partlyCloudy, // 局部多云
  overcast,     // 阴
  fog,          // 雾
  drizzle,      // 毛毛雨
  rain,         // 雨
  freezingRain, // 冻雨
  snow,         // 雪
  snowGrains,   // 雪粒
  showers,      // 阵雨
  snowShowers,  // 阵雪
  thunderstorm, // 雷暴
  unknown;

  static WeatherCondition fromCode(int? code) {
    if (code == null) return WeatherCondition.unknown;
    return switch (code) {
      0 => WeatherCondition.clear,
      1 => WeatherCondition.mainlyClear,
      2 => WeatherCondition.partlyCloudy,
      3 => WeatherCondition.overcast,
      45 || 48 => WeatherCondition.fog,
      51 || 53 || 55 => WeatherCondition.drizzle,
      56 || 57 => WeatherCondition.freezingRain,
      61 || 63 || 65 => WeatherCondition.rain,
      66 || 67 => WeatherCondition.freezingRain,
      71 || 73 || 75 => WeatherCondition.snow,
      77 => WeatherCondition.snowGrains,
      80 || 81 || 82 => WeatherCondition.showers,
      85 || 86 => WeatherCondition.snowShowers,
      95 || 96 || 99 => WeatherCondition.thunderstorm,
      _ => WeatherCondition.unknown,
    };
  }
}
