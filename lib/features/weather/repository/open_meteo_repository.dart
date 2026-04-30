import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../model/current_weather.dart';
import '../model/daily_forecast.dart';
import '../model/geo_location.dart';
import '../model/hourly_forecast.dart';
import '../model/weather_forecast.dart';
import 'weather_repository.dart';

/// [WeatherRepository] 基于 Open-Meteo 的实现。
///
/// 端点参考：
/// - Forecast: https://open-meteo.com/en/docs
/// - Geocoding: https://open-meteo.com/en/docs/geocoding-api
class OpenMeteoRepository implements WeatherRepository {
  OpenMeteoRepository({required Dio dio, required AppConfig config})
    : _dio = dio,
      _config = config;

  final Dio _dio;
  final AppConfig _config;

  static const _currentParams =
      'temperature_2m,relative_humidity_2m,apparent_temperature,'
      'is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m';

  static const _dailyParams =
      'weather_code,temperature_2m_max,temperature_2m_min,'
      'apparent_temperature_max,apparent_temperature_min,sunrise,sunset,'
      'uv_index_max,precipitation_sum,precipitation_probability_max,'
      'wind_speed_10m_max';

  static const _hourlyParams =
      'temperature_2m,apparent_temperature,weather_code,'
      'precipitation_probability,wind_speed_10m';

  @override
  Future<List<GeoLocation>> searchCity(
    String query, {
    String language = 'zh',
    int count = 10,
  }) async {
    final url = '${_config.openMeteoGeocodingHost}/v1/search';
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {
          'name': query,
          'language': language,
          'count': count,
          'format': 'json',
        },
      );
      final results = (res.data?['results'] as List?) ?? const [];
      return results
          .cast<Map<String, dynamic>>()
          .map(GeoLocation.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toException(e, '城市搜索失败');
    }
  }

  @override
  Future<WeatherForecast> fetchForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
    String? timezone,
  }) async {
    final url = '${_config.openMeteoForecastHost}/v1/forecast';
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'forecast_days': forecastDays,
          'timezone': timezone ?? 'auto',
          'current': _currentParams,
          'daily': _dailyParams,
          'hourly': _hourlyParams,
          'wind_speed_unit': 'kmh',
          'temperature_unit': 'celsius',
          'precipitation_unit': 'mm',
        },
      );
      final data = res.data ?? const <String, dynamic>{};
      final current = data['current'] as Map<String, dynamic>?;
      final daily = data['daily'] as Map<String, dynamic>?;
      if (current == null || daily == null) {
        throw const NetworkException('天气数据格式异常');
      }
      final hourly = data['hourly'] as Map<String, dynamic>?;
      return WeatherForecast(
        timezone: data['timezone'] as String? ?? 'UTC',
        current: CurrentWeather.fromJson(current),
        daily: parseDailyForecasts(daily),
        hourly: hourly == null ? const [] : parseHourlyForecasts(hourly),
      );
    } on DioException catch (e) {
      throw _toException(e, '天气查询失败');
    }
  }

  /// [AppErrorInterceptor] 已把 [DioException] 的 `error` 字段替换为 [NetworkException]。
  /// 这里把它取出来直接抛出，附加调用端的语义前缀。
  NetworkException _toException(DioException e, String prefix) {
    final inner = e.error;
    if (inner is NetworkException) {
      return NetworkException(
        '$prefix: ${inner.message}',
        statusCode: inner.statusCode,
        cause: inner.cause,
        stackTrace: inner.stackTrace,
      );
    }
    return NetworkException('$prefix: ${e.message ?? e.type.name}', cause: e);
  }
}

/// 全局唯一的 [WeatherRepository] provider。后续如要切换数据源（如和风），
/// 在此替换实现即可，调用方不感知。
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return OpenMeteoRepository(
    dio: ref.watch(dioProvider),
    config: ref.watch(appConfigProvider),
  );
});
