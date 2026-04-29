import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/controller/preferences_provider.dart';
import '../../settings/model/user_preferences.dart';
import '../../weather/controller/forecast_provider.dart';
import '../../weather/model/current_weather.dart';
import '../../weather/model/daily_forecast.dart';
import '../../weather/model/weather_condition.dart';
import '../data/outfit_catalog.dart';
import '../model/outfit_recommendation.dart';
import '../model/temperature_bracket.dart';

/// 穿搭推荐——基于当前天气 + 今日预报 + 用户偏好（性别 / 风格 / 体感敏感度）派生。
final outfitRecommendationProvider = Provider<OutfitRecommendation?>((ref) {
  final forecastAsync = ref.watch(forecastProvider);
  final forecast = forecastAsync.valueOrNull;
  if (forecast == null) return null;

  final prefs = ref.watch(userPreferencesProvider);
  final today = forecast.daily.isNotEmpty ? forecast.daily.first : null;
  return recommendOutfit(forecast.current, today, prefs);
});

/// 纯函数版本——便于单测，不依赖 Riverpod。
OutfitRecommendation recommendOutfit(
  CurrentWeather c,
  DailyForecast? today,
  UserPreferences prefs,
) {
  final feels = c.apparentTemperatureC;
  final adjustedFeels = adjustFeelsBySensitivity(feels, prefs.thermalSensitivity);
  final bracket = TemperatureBracket.forFeels(adjustedFeels);
  final pieces = outfitPiecesFor(
    bracket: bracket,
    style: prefs.style,
    gender: prefs.gender,
  );

  // 雨天兜底——压过风格规则，安全优先于穿搭风格。
  final rainy =
      c.precipitationMm > 0.5 ||
      (today?.precipitationProbabilityPct ?? 0) >= 60;
  final shoes = rainy ? '防水短靴' : pieces.shoes;

  // tip / accessory 仍然基于"客观"信号（原始体感、温差、UV、降水），
  // 与个人敏感度无关——避免怕冷的用户在 30°C 看到"冷"的提示。
  final dayDelta = (today?.tempMaxC ?? feels) - (today?.tempMinC ?? feels);
  final pop = today?.precipitationProbabilityPct ?? 0;
  final isThunder = c.condition == WeatherCondition.thunderstorm;
  final isSnowy = c.condition == WeatherCondition.snow ||
      c.condition == WeatherCondition.snowShowers ||
      c.condition == WeatherCondition.snowGrains;
  final isFoggy = c.condition == WeatherCondition.fog;

  String tip;
  if (isThunder) {
    tip = '雷暴天气，避免在户外停留';
  } else if (isSnowy) {
    tip = '下雪了，注意保暖防滑';
  } else if (pop >= 60) {
    tip = '今天有较大概率降雨，建议带伞';
  } else if (dayDelta >= 8) {
    tip = '早晚温差较大，建议带外套';
  } else if (feels >= 30) {
    tip = '高温天气，注意防晒补水';
  } else if (isFoggy) {
    tip = '能见度低，出行注意安全';
  } else {
    tip = '体感舒适，按推荐穿即可';
  }

  String accessory;
  String emoji;
  if (pop >= 60 || c.precipitationMm > 0.5) {
    accessory = '折叠雨伞（${pop >= 60 ? "降雨概率高" : "正在降水"}）';
    emoji = '☂️';
  } else if ((today?.uvIndexMax ?? 0) >= 7) {
    accessory = '防晒帽 / 太阳镜（紫外线强）';
    emoji = '🧢';
  } else if (dayDelta >= 8) {
    accessory = '折叠雨伞（傍晚可能有阵雨）';
    emoji = '💼';
  } else {
    accessory = '保温水杯，记得多喝水';
    emoji = '💧';
  }

  return OutfitRecommendation(
    top: pieces.top,
    bottom: pieces.bottom,
    jacket: pieces.jacket,
    shoes: shoes,
    tip: tip,
    accessory: accessory,
    accessoryEmoji: emoji,
  );
}
