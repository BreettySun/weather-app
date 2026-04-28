import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../weather/controller/forecast_provider.dart';
import '../../weather/model/current_weather.dart';
import '../../weather/model/daily_forecast.dart';
import '../../weather/model/weather_condition.dart';
import '../model/outfit_recommendation.dart';

/// 穿搭推荐——基于当前天气 + 今日预报派生。
///
/// 当前为基于温度区间 / 降水概率 / 温差的简单规则版本，
/// 后续可替换为 LLM / 个性化模型。
final outfitRecommendationProvider = Provider<OutfitRecommendation?>((ref) {
  final forecastAsync = ref.watch(forecastProvider);
  final forecast = forecastAsync.valueOrNull;
  if (forecast == null) return null;

  final today = forecast.daily.isNotEmpty ? forecast.daily.first : null;
  return _recommend(forecast.current, today);
});

OutfitRecommendation _recommend(CurrentWeather c, DailyForecast? today) {
  final feels = c.apparentTemperatureC;

  final top = switch (feels) {
    < 5 => '保暖打底衫',
    < 12 => '羊毛针织衫',
    < 18 => '长袖衬衫',
    < 24 => '薄长袖 / T恤',
    < 28 => '透气短袖',
    _ => '冰丝短袖',
  };

  final bottom = switch (feels) {
    < 5 => '加绒长裤',
    < 12 => '厚款长裤',
    < 22 => '休闲长裤',
    < 28 => '九分裤',
    _ => '透气短裤',
  };

  final jacket = switch (feels) {
    < 0 => '羽绒服',
    < 8 => '加厚外套',
    < 15 => '夹克 / 风衣',
    < 22 => '薄风衣',
    _ => '无需外套',
  };

  final shoes = c.precipitationMm > 0.5 || (today?.precipitationProbabilityPct ?? 0) >= 60
      ? '防水短靴'
      : feels < 5
          ? '保暖短靴'
          : feels < 22
              ? '运动鞋'
              : '帆布鞋';

  // 大字提示——优先级：极端天气 > 温差 > 普通
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

  // 随身携带
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
    top: top,
    bottom: bottom,
    jacket: jacket,
    shoes: shoes,
    tip: tip,
    accessory: accessory,
    accessoryEmoji: emoji,
  );
}
