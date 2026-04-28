import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/weather_forecast.dart';
import '../repository/open_meteo_repository.dart';
import 'location_provider.dart';

/// 天气预报。依赖 [selectedLocationProvider]——位置变更时自动重新拉取。
///
/// 当未选位置时直接抛错，调用方应在 UI 中按 AsyncValue 状态分支处理。
final forecastProvider = FutureProvider<WeatherForecast>((ref) async {
  final location = ref.watch(selectedLocationProvider);
  if (location == null) {
    throw StateError('No location selected');
  }
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.fetchForecast(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});
