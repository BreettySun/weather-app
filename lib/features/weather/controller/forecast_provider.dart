import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/weather_forecast.dart';
import '../repository/forecast_cache.dart';
import '../repository/open_meteo_repository.dart';
import 'location_provider.dart';

/// 天气预报。依赖 [selectedLocationProvider]——位置变更时自动重新拉取。
///
/// 三段式输出：
/// 1. 若有匹配当前位置的本地缓存 → 立即 yield 缓存，UI 不用先 loading
/// 2. 拉取最新预报，成功 → 写缓存 + yield 新数据
/// 3. 失败但有缓存 → 静默吞错，停留在缓存态（用户至少看到"上次的天气"）
///    失败且没缓存 → 抛错由 UI 走 error 分支
final forecastProvider = StreamProvider<WeatherForecast>((ref) async* {
  final location = ref.watch(selectedLocationProvider);
  if (location == null) {
    throw StateError('No location selected');
  }
  final repo = ref.watch(weatherRepositoryProvider);
  final cache = ref.watch(forecastCacheProvider);

  final cached = cache.read();
  final hasUsableCache = cached != null && cached.matches(location);
  if (hasUsableCache) {
    yield cached.forecast;
  }

  try {
    final fresh = await repo.fetchForecast(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    yield fresh;
    // 缓存写入失败（如磁盘满）不应影响 UI——await 但忽略错误。
    await cache.write(forecast: fresh, location: location).catchError((_) {});
  } catch (e) {
    // 已经 yield 过缓存的话，吞掉网络错误，让用户看到"陈旧但可用"的数据；
    // 否则抛出去走 error 状态。
    if (!hasUsableCache) rethrow;
  }
});
