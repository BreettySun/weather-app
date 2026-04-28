import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

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
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});
