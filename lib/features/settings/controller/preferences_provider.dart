import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/units/units.dart';
import '../model/user_preferences.dart';

/// SharedPreferences 中存放用户偏好的 key——单条 JSON 字符串，
/// 字段演进时在 [UserPreferences.fromJson] 内做兜底。
const _kUserPrefsKey = 'user_preferences.v1';

/// 用户偏好状态管理。构造期同步加载已有值；setter 触发持久化。
class UserPreferencesController extends StateNotifier<UserPreferences> {
  UserPreferencesController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static UserPreferences _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kUserPrefsKey);
    if (raw == null || raw.isEmpty) return const UserPreferences();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return UserPreferences.fromJson(decoded);
      }
    } catch (e, st) {
      // 格式损坏时清掉脏数据，使用默认值——避免每次启动都尝试解析失败。
      debugPrint('[UserPreferences] failed to parse, resetting: $e\n$st');
      prefs.remove(_kUserPrefsKey);
    }
    return const UserPreferences();
  }

  void setGender(GenderPreference value) {
    _update(state.copyWith(gender: value));
  }

  void setStyle(ClothingStyle value) {
    _update(state.copyWith(style: value));
  }

  void setThermalSensitivity(double value) {
    _update(state.copyWith(thermalSensitivity: value.clamp(0.0, 1.0)));
  }

  void setDailyReminderEnabled(bool value) {
    _update(state.copyWith(dailyReminderEnabled: value));
  }

  void setReminderTime(int hour, int minute) {
    _update(state.copyWith(reminderHour: hour, reminderMinute: minute));
  }

  void setRainAlertEnabled(bool value) {
    _update(state.copyWith(rainAlertEnabled: value));
  }

  void setTemperatureUnit(TemperatureUnit value) {
    _update(state.copyWith(temperatureUnit: value));
  }

  void setWindSpeedUnit(WindSpeedUnit value) {
    _update(state.copyWith(windSpeedUnit: value));
  }

  void _update(UserPreferences next) {
    state = next;
    // fire-and-forget：SharedPreferences 内部已串行化写入，UI 不需要等。
    unawaited(_prefs.setString(_kUserPrefsKey, jsonEncode(next.toJson())));
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesController, UserPreferences>((ref) {
      return UserPreferencesController(ref.watch(sharedPreferencesProvider));
    });
