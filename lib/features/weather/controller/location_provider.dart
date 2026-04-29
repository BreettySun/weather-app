import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import '../model/geo_location.dart';

/// 当前选中的位置。引导页 / 城市搜索页负责写入；天气页与路由 watch 它驱动取数与跳转。
///
/// 持久化在 [SharedPreferences] 下的 [_kSelectedLocationKey]，构造期同步加载——
/// 这样冷启动时路由层就能立即决定是去 `/onboarding` 还是 `/weather`。
const _kSelectedLocationKey = 'selected_location.v1';

class SelectedLocationController extends StateNotifier<GeoLocation?> {
  SelectedLocationController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static GeoLocation? _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kSelectedLocationKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return GeoLocation.fromJson(decoded);
      }
    } catch (e, st) {
      debugPrint('[SelectedLocation] failed to parse, resetting: $e\n$st');
      prefs.remove(_kSelectedLocationKey);
    }
    return null;
  }

  /// 写入新位置；传 `null` 等同于清除（如登出）。
  void set(GeoLocation? value) {
    state = value;
    if (value == null) {
      unawaited(_prefs.remove(_kSelectedLocationKey));
    } else {
      unawaited(
        _prefs.setString(_kSelectedLocationKey, jsonEncode(value.toJson())),
      );
    }
  }

  void clear() => set(null);
}

final selectedLocationProvider =
    StateNotifierProvider<SelectedLocationController, GeoLocation?>((ref) {
      return SelectedLocationController(ref.watch(sharedPreferencesProvider));
    });
