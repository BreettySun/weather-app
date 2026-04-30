import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import '../model/geo_location.dart';
import '../model/weather_forecast.dart';

/// 上一次成功的天气预报 + 抓取时刻 + 取数所用的经纬度。
///
/// 用 lat/lng 而不是城市名来匹配——避免"同名不同处"的歧义；
/// 4 位小数（≈11m）的精度足以判断"是不是同一个查询点"。
@immutable
class CachedForecast {
  const CachedForecast({
    required this.forecast,
    required this.fetchedAt,
    required this.latitude,
    required this.longitude,
  });

  final WeatherForecast forecast;
  final DateTime fetchedAt;
  final double latitude;
  final double longitude;

  bool matches(GeoLocation loc) =>
      _close(latitude, loc.latitude) && _close(longitude, loc.longitude);

  static bool _close(double a, double b) => (a - b).abs() < 0.0001;
}

/// v1 → v2：模型加了 hourly 字段。v1 旧值在升级首启时检测到 key 不存在，
/// 直接走"无缓存"分支拉网络。不写迁移逻辑——payload 结构变了不值得。
const _kCacheKey = 'forecast_cache.v2';

/// 把上一次成功的预报缓存到 SharedPreferences——冷启动 / 弱网时立即可用。
///
/// 单条记录策略：换城市后只保留最新城市的缓存，避免 keys 无限增长；
/// 反正常用场景就是"在主用城市附近"，不会频繁切换。
class ForecastCache {
  ForecastCache(this._prefs);

  final SharedPreferences _prefs;

  CachedForecast? read() {
    final raw = _prefs.getString(_kCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      return CachedForecast(
        forecast: WeatherForecast.fromCacheJson(
          (map['forecast'] as Map).cast<String, dynamic>(),
        ),
        fetchedAt: DateTime.parse(map['fetchedAt'] as String),
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
    } catch (e, st) {
      debugPrint('[ForecastCache] failed to parse, dropping: $e\n$st');
      _prefs.remove(_kCacheKey);
      return null;
    }
  }

  Future<void> write({
    required WeatherForecast forecast,
    required GeoLocation location,
  }) {
    final payload = jsonEncode({
      'forecast': forecast.toCacheJson(),
      'fetchedAt': DateTime.now().toIso8601String(),
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
    return _prefs.setString(_kCacheKey, payload);
  }

  Future<void> clear() => _prefs.remove(_kCacheKey);
}

final forecastCacheProvider = Provider<ForecastCache>((ref) {
  return ForecastCache(ref.watch(sharedPreferencesProvider));
});
