import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/outfit/controller/outfit_provider.dart';
import '../../features/outfit/model/outfit_recommendation.dart';
import '../../features/settings/controller/preferences_provider.dart';
import '../../features/settings/model/user_preferences.dart';
import '../../features/weather/controller/forecast_provider.dart';
import '../../features/weather/controller/location_provider.dart';
import '../../features/weather/model/current_weather.dart';
import '../../features/weather/model/daily_forecast.dart';
import '../../features/weather/model/geo_location.dart';
import '../../features/weather/model/weather_condition.dart';
import '../../features/weather/model/weather_forecast.dart';
import '../units/units.dart';

/// 桌面小组件——Android AppWidget / iOS WidgetKit 名称约定。
///
/// `androidName` 必须与 `WeatherWidgetProvider.kt` 类名一致；
/// `iOSName` 对应 Widget Extension 的 `kind` 字符串。
const _androidWidgetName = 'WeatherWidgetProvider';
const _iOSWidgetName = 'WeatherWidget';

/// 把当前预报 + 推荐推到原生小组件。无预报时（首次冷启动 / 错误状态）跳过——
/// 让小组件保留上一次成功结果，而不是闪现空白。
Future<void> pushHomeWidget({
  required GeoLocation? location,
  required WeatherForecast? forecast,
  required OutfitRecommendation? outfit,
  required UserPreferences prefs,
}) async {
  if (forecast == null || outfit == null) return;
  final today = forecast.daily.isNotEmpty ? forecast.daily.first : null;
  final payload = _buildPayload(
    location: location,
    current: forecast.current,
    today: today,
    outfit: outfit,
    prefs: prefs,
  );

  try {
    await Future.wait(
      payload.entries.map((e) => HomeWidget.saveWidgetData(e.key, e.value)),
    );
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  } catch (e, st) {
    debugPrint('[HomeWidget] sync failed: $e\n$st');
  }
}

/// 在应用启动后挂在 [ProviderContainer] 上——预报 / 偏好任一变更都触发同步。
///
/// 返回 dispose 回调，调用方在 app 销毁时调用即可。
VoidCallback bindHomeWidgetSync(WidgetRef ref) {
  void sync() {
    final forecast = ref.read(forecastProvider).valueOrNull;
    final outfit = ref.read(outfitRecommendationProvider);
    final prefs = ref.read(userPreferencesProvider);
    final location = ref.read(selectedLocationProvider);
    pushHomeWidget(
      location: location,
      forecast: forecast,
      outfit: outfit,
      prefs: prefs,
    );
  }

  final subs = <ProviderSubscription>[
    ref.listenManual(forecastProvider, (_, _) => sync()),
    ref.listenManual(outfitRecommendationProvider, (_, _) => sync()),
    ref.listenManual(userPreferencesProvider, (_, _) => sync()),
    ref.listenManual(selectedLocationProvider, (_, _) => sync()),
  ];
  // 立刻同步一次——首屏冷启动时通常已有缓存的偏好与位置。
  sync();
  return () {
    for (final s in subs) {
      s.close();
    }
  };
}

Map<String, Object> _buildPayload({
  required GeoLocation? location,
  required CurrentWeather current,
  required DailyForecast? today,
  required OutfitRecommendation outfit,
  required UserPreferences prefs,
}) {
  final tempUnit = prefs.temperatureUnit;
  return <String, Object>{
    'widget.location': _displayName(location),
    'widget.tempNow': formatTemperature(current.temperatureC, tempUnit),
    'widget.feelsLike': formatTemperature(current.apparentTemperatureC, tempUnit),
    'widget.condition': _conditionLabel(current.condition),
    'widget.tempHigh':
        today != null ? formatTemperatureShort(today.tempMaxC, tempUnit) : '--',
    'widget.tempLow':
        today != null ? formatTemperatureShort(today.tempMinC, tempUnit) : '--',
    'widget.outfitTop': outfit.top,
    'widget.outfitBottom': outfit.bottom,
    'widget.outfitJacket': outfit.jacket,
    'widget.outfitShoes': outfit.shoes,
    'widget.tip': outfit.tip,
    'widget.accessory': '${outfit.accessoryEmoji} ${outfit.accessory}',
    'widget.updatedAt': _hourMinute(DateTime.now()),
  };
}

String _displayName(GeoLocation? loc) {
  if (loc == null) return '当前位置';
  final admin = loc.admin1;
  if (admin != null && admin.isNotEmpty && admin != loc.name) {
    return '${loc.name} · $admin';
  }
  return loc.name;
}

String _conditionLabel(WeatherCondition c) => switch (c) {
      WeatherCondition.clear => '晴',
      WeatherCondition.mainlyClear => '晴间多云',
      WeatherCondition.partlyCloudy => '局部多云',
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
      WeatherCondition.unknown => '--',
    };

String _hourMinute(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
