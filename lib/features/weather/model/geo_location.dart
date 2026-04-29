import 'package:flutter/foundation.dart';

/// 地理位置（城市搜索结果或定位反查结果）。
@immutable
class GeoLocation {
  const GeoLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.country,
    this.countryCode,
    this.timezone,
    this.population,
  });

  final String name;
  final double latitude;
  final double longitude;

  /// 一级行政区（省 / 州）
  final String? admin1;
  final String? country;
  final String? countryCode;
  final String? timezone;
  final int? population;

  /// 解析 Open-Meteo Geocoding API 单条结果，也用作本地缓存的反序列化。
  /// 文档：https://open-meteo.com/en/docs/geocoding-api
  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      admin1: json['admin1'] as String?,
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
      timezone: json['timezone'] as String?,
      population: json['population'] as int?,
    );
  }

  /// 与 [GeoLocation.fromJson] 对称，键名沿用 Open-Meteo 风格。
  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    if (admin1 != null) 'admin1': admin1,
    if (country != null) 'country': country,
    if (countryCode != null) 'country_code': countryCode,
    if (timezone != null) 'timezone': timezone,
    if (population != null) 'population': population,
  };

  /// 给定经纬度的临时 [GeoLocation]（如来自 GPS，但未做反查）。
  factory GeoLocation.coords({
    required double latitude,
    required double longitude,
    String name = '当前位置',
  }) {
    return GeoLocation(
      name: name,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
