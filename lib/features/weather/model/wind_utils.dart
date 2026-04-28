import 'weather_condition.dart';

/// 把风向（度，0=北，顺时针）转中文方位。
String windDirectionToChinese(int degrees) {
  final normalized = ((degrees % 360) + 360) % 360;
  const labels = ['北', '东北', '东', '东南', '南', '西南', '西', '西北', '北'];
  // 8 个方位平均分布，每 45° 一个；±22.5° 容差
  final index = ((normalized + 22.5) ~/ 45) % 8;
  return labels[index];
}

/// 把风速（km/h）转蒲福风级 0-12。
int windSpeedKmhToBeaufort(double kmh) {
  const thresholds = [
    1.0, 5.0, 11.0, 19.0, 28.0, 38.0, 49.0, 61.0, 74.0, 88.0, 102.0, 117.0,
  ];
  for (var i = 0; i < thresholds.length; i++) {
    if (kmh < thresholds[i]) return i;
  }
  return 12;
}

/// 用于 UI 展示的天气条件中文短名。
String weatherConditionLabel(WeatherCondition c) {
  return switch (c) {
    WeatherCondition.clear => '晴',
    WeatherCondition.mainlyClear => '晴间多云',
    WeatherCondition.partlyCloudy => '多云转晴',
    WeatherCondition.overcast => '阴',
    WeatherCondition.fog => '雾',
    WeatherCondition.drizzle => '毛毛雨',
    WeatherCondition.rain => '雨',
    WeatherCondition.freezingRain => '冻雨',
    WeatherCondition.snow => '雪',
    WeatherCondition.snowGrains => '雪粒',
    WeatherCondition.showers => '阵雨',
    WeatherCondition.snowShowers => '阵雪',
    WeatherCondition.thunderstorm => '雷暴',
    WeatherCondition.unknown => '—',
  };
}
