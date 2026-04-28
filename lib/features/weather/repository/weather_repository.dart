import '../model/geo_location.dart';
import '../model/weather_forecast.dart';

/// 天气数据访问的抽象接口。具体数据源（Open-Meteo / 和风等）实现此接口。
///
/// 每个方法可能抛出 [core/error/app_exception] 中定义的 `NetworkException`。
abstract interface class WeatherRepository {
  /// 按关键字搜索城市，返回候选地理位置列表。
  ///
  /// [language] 控制返回的本地化名称，默认中文。
  /// [count] 控制返回条数上限。
  Future<List<GeoLocation>> searchCity(
    String query, {
    String language = 'zh',
    int count = 10,
  });

  /// 获取指定经纬度的当前天气 + 多日预报。
  ///
  /// [forecastDays] 区间为 1-16，超出由数据源截断。
  Future<WeatherForecast> fetchForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
    String? timezone,
  });
}
