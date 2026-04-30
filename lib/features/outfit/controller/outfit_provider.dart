import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/model/activity.dart';
import '../../settings/controller/preferences_provider.dart';
import '../../settings/model/user_preferences.dart';
import '../../weather/controller/forecast_provider.dart';
import '../../weather/model/current_weather.dart';
import '../../weather/model/daily_forecast.dart';
import '../../weather/model/hourly_forecast.dart';
import '../../weather/model/weather_condition.dart';
import '../data/outfit_catalog.dart';
import '../model/outfit_recommendation.dart';
import '../model/temperature_bracket.dart';

/// 默认卡的穿搭推荐——基于当前天气 + 今日预报 + 用户偏好（性别 / 风格 / 体感敏感度）派生。
///
/// 默认 activity 为 [Activity.casual]——P6 阶段会改为按 weekday 推导（commute / casual）。
final outfitRecommendationProvider = Provider<OutfitRecommendation?>((ref) {
  final forecastAsync = ref.watch(forecastProvider);
  final forecast = forecastAsync.valueOrNull;
  if (forecast == null) return null;

  final prefs = ref.watch(userPreferencesProvider);
  final today = forecast.daily.isNotEmpty ? forecast.daily.first : null;
  return recommendOutfit(
    current: forecast.current,
    today: today,
    prefs: prefs,
    activity: Activity.casual,
  );
});

/// 纯函数版本——便于单测，不依赖 Riverpod。
///
/// [targetHour] 给定时（事件卡场景），用其 apparent temperature 决定 bracket，
/// tip / accessory 仍用 [current] 的客观信号——避免怕冷的人在 30°C 看到冷的提示。
OutfitRecommendation recommendOutfit({
  required CurrentWeather current,
  required DailyForecast? today,
  HourlyForecast? targetHour,
  Activity activity = Activity.casual,
  required UserPreferences prefs,
}) {
  final feels = targetHour?.apparentTemperatureC ?? current.apparentTemperatureC;
  final adjustedFeels = adjustFeelsBySensitivity(feels, prefs.thermalSensitivity);
  final bracket = TemperatureBracket.forFeels(adjustedFeels);
  final pieces = outfitPiecesFor(
    bracket: bracket,
    style: prefs.style,
    gender: prefs.gender,
    activity: activity,
  );

  // 雨天兜底——压过所有 overlay（包括 activity 的运动鞋 / 徒步鞋），安全 > 风格。
  // 优先看 targetHour 的降水概率；否则用 current + today 的聚合信号。
  final rainAtHour = (targetHour?.precipitationProbabilityPct ?? -1) >= 60;
  final rainGeneral = current.precipitationMm > 0.5 ||
      (today?.precipitationProbabilityPct ?? 0) >= 60;
  final rainy = targetHour != null ? rainAtHour : rainGeneral;
  final shoes = rainy ? '防水短靴' : pieces.shoes;

  // tip / accessory 仍然基于"客观"信号——使用 current 的原始 feels，
  // 与个人敏感度 / activity / targetHour 都无关。
  final rawFeels = current.apparentTemperatureC;
  final dayDelta = (today?.tempMaxC ?? rawFeels) - (today?.tempMinC ?? rawFeels);
  final pop = today?.precipitationProbabilityPct ?? 0;
  final isThunder = current.condition == WeatherCondition.thunderstorm;
  final isSnowy = current.condition == WeatherCondition.snow ||
      current.condition == WeatherCondition.snowShowers ||
      current.condition == WeatherCondition.snowGrains;
  final isFoggy = current.condition == WeatherCondition.fog;

  String tip;
  if (isThunder) {
    tip = '雷暴天气，避免在户外停留';
  } else if (isSnowy) {
    tip = '下雪了，注意保暖防滑';
  } else if (pop >= 60) {
    tip = '今天有较大概率降雨，建议带伞';
  } else if (dayDelta >= 8) {
    tip = '早晚温差较大，建议带外套';
  } else if (rawFeels >= 30) {
    tip = '高温天气，注意防晒补水';
  } else if (isFoggy) {
    tip = '能见度低，出行注意安全';
  } else {
    tip = '体感舒适，按推荐穿即可';
  }

  String accessory;
  String emoji;
  if (pop >= 60 || current.precipitationMm > 0.5) {
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
