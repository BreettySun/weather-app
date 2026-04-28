import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/weather/model/geo_location.dart';
import '../error/app_exception.dart';
import 'permission_helper.dart';

class LocationService {
  const LocationService();

  /// 获取当前位置坐标。失败时抛出 [LocationException]。
  Future<Position> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    await LocationPermissionHelper.ensureLocationPermission();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      );
    } on LocationException {
      rethrow;
    } catch (e, st) {
      throw LocationException('获取定位失败', cause: e, stackTrace: st);
    }
  }

  /// 获取当前位置并尝试反查城市名，组装为 [GeoLocation]。
  ///
  /// 反查使用 iOS CLGeocoder / Android Geocoder（系统原生），
  /// 无网络或失败时降级返回 "当前位置" 作为名称。坐标始终有效。
  Future<GeoLocation> currentLocation({
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    final position = await currentPosition(accuracy: accuracy);
    final placemark = await _tryReverseGeocode(
      position.latitude,
      position.longitude,
    );
    return GeoLocation(
      name: _bestName(placemark),
      latitude: position.latitude,
      longitude: position.longitude,
      admin1: placemark?.administrativeArea,
      country: placemark?.country,
      countryCode: placemark?.isoCountryCode,
    );
  }

  Future<Placemark?> _tryReverseGeocode(double lat, double lon) async {
    try {
      await setLocaleIdentifier('zh_CN');
      final placemarks = await placemarkFromCoordinates(lat, lon);
      return placemarks.isEmpty ? null : placemarks.first;
    } catch (_) {
      // 反查是 best-effort：网络异常 / 平台不支持 / 无 Google Play Services 等情况都直接降级。
      return null;
    }
  }

  static String _bestName(Placemark? p) {
    if (p == null) return '当前位置';
    for (final candidate in [
      p.locality,
      p.subAdministrativeArea,
      p.administrativeArea,
    ]) {
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return '当前位置';
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});
