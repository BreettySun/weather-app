import 'package:geolocator/geolocator.dart';

import '../error/app_exception.dart';

/// 定位权限申请助手。
///
/// [ensureLocationPermission] 处理"定位服务未开启 / 权限被拒 / 永久拒绝"三种异常情形，
/// 失败时抛出 [LocationException] 由调用方统一处理。
abstract final class LocationPermissionHelper {
  static Future<void> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('定位服务未开启');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('未授予定位权限');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException('定位权限被永久拒绝，请在系统设置中开启');
    }
  }
}
