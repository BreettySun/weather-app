import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局只读配置。集中维护外部服务地址等可调参数。
///
/// 使用 [String.fromEnvironment] 读取构建期注入值：
/// `flutter run --dart-define=OPEN_METEO_FORECAST_HOST=https://api.open-meteo.com`
@immutable
class AppConfig {
  const AppConfig({
    required this.openMeteoForecastHost,
    required this.openMeteoGeocodingHost,
  });

  /// Open-Meteo 天气预报 API host（无路径），默认官方公网地址。
  final String openMeteoForecastHost;

  /// Open-Meteo 城市搜索 / 反查 API host（无路径），默认官方公网地址。
  final String openMeteoGeocodingHost;

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      openMeteoForecastHost: String.fromEnvironment(
        'OPEN_METEO_FORECAST_HOST',
        defaultValue: 'https://api.open-meteo.com',
      ),
      openMeteoGeocodingHost: String.fromEnvironment(
        'OPEN_METEO_GEOCODING_HOST',
        defaultValue: 'https://geocoding-api.open-meteo.com',
      ),
    );
  }
}

/// 在 ProviderScope.overrides 中可替换为测试 / mock 配置。
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
